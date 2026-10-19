#pragma once
#include <windows.h>
#include <WebView2.h>
#include <wil/com.h>
#include <wrl/event.h>
#include <memory>
#include <vector>
#include <string>
#include <algorithm>
#include <filesystem>

namespace ecjtu {
inline bool browserMenuDark = false;
inline COLORREF browserMenuBase = RGB(255,255,255);
inline COLORREF BrowserMenuSurface() {
  const double white = browserMenuDark ? .10 : .60;
  return RGB(static_cast<BYTE>(GetRValue(browserMenuBase)*(1-white)+255*white),
    static_cast<BYTE>(GetGValue(browserMenuBase)*(1-white)+255*white),
    static_cast<BYTE>(GetBValue(browserMenuBase)*(1-white)+255*white));
}
struct BrowserMenuRow { std::wstring text; bool separator=false, submenu=false; };
struct BrowserMenuPaint {
  std::vector<std::unique_ptr<BrowserMenuRow>> rows;
  HFONT font=nullptr; HBRUSH background=nullptr;
  int dpi=96;
  int scaled(int value) const { return MulDiv(value,dpi,96); }
};
inline LRESULT CALLBACK BrowserMenuProc(HWND window, UINT message, WPARAM w, LPARAM l) {
  auto* paint = reinterpret_cast<BrowserMenuPaint*>(GetWindowLongPtr(window,GWLP_USERDATA));
  if (message == WM_NCCREATE) {
    paint = static_cast<BrowserMenuPaint*>(reinterpret_cast<CREATESTRUCT*>(l)->lpCreateParams);
    SetWindowLongPtr(window,GWLP_USERDATA,reinterpret_cast<LONG_PTR>(paint));
  }
  if (paint && message == WM_MEASUREITEM) {
    auto* measure = reinterpret_cast<MEASUREITEMSTRUCT*>(l);
    auto* row = reinterpret_cast<BrowserMenuRow*>(measure->itemData);
    HDC dc=GetDC(window); auto old=SelectObject(dc,paint->font);
    SIZE size{}; GetTextExtentPoint32W(dc,row->text.c_str(),static_cast<int>(row->text.size()),&size);
    SelectObject(dc,old); ReleaseDC(window,dc);
    measure->itemWidth=static_cast<UINT>((std::max)(paint->scaled(180),static_cast<int>(size.cx)+paint->scaled(56)));
    measure->itemHeight=paint->scaled(row->separator ? 9 : 34);
    return TRUE;
  }
  if (paint && message == WM_DRAWITEM) {
    auto* draw=reinterpret_cast<DRAWITEMSTRUCT*>(l);
    auto* row=reinterpret_cast<BrowserMenuRow*>(draw->itemData);
    const COLORREF surface=BrowserMenuSurface();
    const COLORREF hover=browserMenuDark?RGB(65,68,73):RGB(233,239,245);
    HBRUSH brush=CreateSolidBrush((draw->itemState&ODS_SELECTED)?hover:surface);
    FillRect(draw->hDC,&draw->rcItem,brush); DeleteObject(brush);
    RECT rect=draw->rcItem;
    if(row->separator) {
      const int y=(rect.top+rect.bottom)/2;
      HPEN pen=CreatePen(PS_SOLID,1,browserMenuDark?RGB(77,77,77):RGB(218,222,227));
      auto old=SelectObject(draw->hDC,pen); MoveToEx(draw->hDC,rect.left+paint->scaled(10),y,nullptr);
      LineTo(draw->hDC,rect.right-paint->scaled(10),y); SelectObject(draw->hDC,old); DeleteObject(pen);
      return TRUE;
    }
    SetBkMode(draw->hDC,TRANSPARENT);
    SetTextColor(draw->hDC,(draw->itemState&ODS_DISABLED)?RGB(140,145,151):
      browserMenuDark?RGB(238,238,238):RGB(35,39,45));
    auto old=SelectObject(draw->hDC,paint->font);
    rect.left+=paint->scaled(24); rect.right-=paint->scaled(24);
    DrawTextW(draw->hDC,row->text.c_str(),-1,&rect,DT_SINGLELINE|DT_VCENTER|DT_HIDEPREFIX);
    if(row->submenu) { rect.left=rect.right; rect.right+=paint->scaled(20); DrawTextW(draw->hDC,L"›",-1,&rect,DT_SINGLELINE|DT_VCENTER); }
    if(draw->itemState&ODS_CHECKED) { rect=draw->rcItem; rect.left+=paint->scaled(6); DrawTextW(draw->hDC,L"✓",-1,&rect,DT_SINGLELINE|DT_VCENTER); }
    SelectObject(draw->hDC,old); return TRUE;
  }
  return DefWindowProcW(window,message,w,l);
}
inline HMENU BuildBrowserMenu(ICoreWebView2ContextMenuItemCollection* items, BrowserMenuPaint& paint) {
  HMENU menu=CreatePopupMenu();
  MENUINFO info{sizeof(info)}; info.fMask=MIM_BACKGROUND; info.hbrBack=paint.background; SetMenuInfo(menu,&info);
  UINT count=0; items->get_Count(&count);
  for(UINT i=0;i<count;++i) {
    wil::com_ptr<ICoreWebView2ContextMenuItem> item; if(FAILED(items->GetValueAtIndex(i,item.put()))) continue;
    auto row=std::make_unique<BrowserMenuRow>();
    COREWEBVIEW2_CONTEXT_MENU_ITEM_KIND kind{}; item->get_Kind(&kind);
    row->separator=kind==COREWEBVIEW2_CONTEXT_MENU_ITEM_KIND_SEPARATOR;
    row->submenu=kind==COREWEBVIEW2_CONTEXT_MENU_ITEM_KIND_SUBMENU;
    wil::unique_cotaskmem_string label; item->get_Label(&label); if(label) row->text=label.get();
    BOOL enabled=TRUE,checked=FALSE; INT32 command=0;
    item->get_IsEnabled(&enabled); item->get_IsChecked(&checked); item->get_CommandId(&command);
    MENUITEMINFOW native{sizeof(native)};
    native.fMask=MIIM_FTYPE|MIIM_STATE|MIIM_ID|MIIM_DATA;
    native.fType=MFT_OWNERDRAW; native.fState=(enabled?MFS_ENABLED:MFS_DISABLED)|(checked?MFS_CHECKED:0);
    native.wID=static_cast<UINT>(command); native.dwItemData=reinterpret_cast<ULONG_PTR>(row.get());
    if(row->submenu) {
      wil::com_ptr<ICoreWebView2ContextMenuItemCollection> children;
      if(SUCCEEDED(item->get_Children(children.put())) && children) {
        native.fMask|=MIIM_SUBMENU; native.hSubMenu=BuildBrowserMenu(children.get(),paint);
      }
    }
    if(row->separator) native.fState=MFS_DISABLED;
    paint.rows.push_back(std::move(row)); InsertMenuItemW(menu,i,TRUE,&native);
  }
  return menu;
}
inline void InstallBrowserContextMenu(ICoreWebView2* webview, HWND parent) {
  wil::com_ptr<ICoreWebView2_11> menuView;
  if(FAILED(webview->QueryInterface(IID_PPV_ARGS(menuView.put())))) return;
  EventRegistrationToken token{};
  menuView->add_ContextMenuRequested(Microsoft::WRL::Callback<ICoreWebView2ContextMenuRequestedEventHandler>(
    [parent](ICoreWebView2*, ICoreWebView2ContextMenuRequestedEventArgs* args)->HRESULT {
      wil::com_ptr<ICoreWebView2ContextMenuItemCollection> items;
      if(FAILED(args->get_MenuItems(items.put()))) return S_OK;
      wil::com_ptr<ICoreWebView2Deferral> deferral; args->GetDeferral(deferral.put());
      args->put_Handled(TRUE);
      BrowserMenuPaint paint; paint.dpi=GetDpiForWindow(parent);
      static const bool fontRegistered=[] {
        wchar_t executable[32768]{};
        GetModuleFileNameW(nullptr,executable,32768);
        const auto font=std::filesystem::path(executable).parent_path()/L"data/flutter_assets/assets/fonts/SourceHanSansCN-Regular.otf";
        return AddFontResourceExW(font.c_str(),FR_PRIVATE,nullptr)>0;
      }();
      paint.font=CreateFontW(-paint.scaled(14),0,0,0,FW_NORMAL,FALSE,FALSE,FALSE,DEFAULT_CHARSET,
        OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,CLEARTYPE_QUALITY,DEFAULT_PITCH,
        fontRegistered?L"Source Han Sans CN":L"Microsoft YaHei UI");
      paint.background=CreateSolidBrush(BrowserMenuSurface());
      static const wchar_t* name=L"EcjtuWebContextMenuOwner";
      WNDCLASSW cls{}; cls.hInstance=GetModuleHandleW(nullptr); cls.lpfnWndProc=BrowserMenuProc; cls.lpszClassName=name;
      RegisterClassW(&cls);
      HWND owner=CreateWindowExW(WS_EX_TOOLWINDOW,name,L"",WS_POPUP,0,0,0,0,
        GetAncestor(parent,GA_ROOT),nullptr,cls.hInstance,&paint);
      HMENU menu=BuildBrowserMenu(items.get(),paint);
      POINT cursor{}; GetCursorPos(&cursor);
      const auto selected=TrackPopupMenuEx(menu,TPM_RETURNCMD|TPM_RIGHTBUTTON,cursor.x,cursor.y,owner,nullptr);
      if(selected) args->put_SelectedCommandId(static_cast<INT32>(selected));
      DestroyMenu(menu); DestroyWindow(owner); DeleteObject(paint.font); DeleteObject(paint.background);
      if(deferral) deferral->Complete();
      return S_OK;
    }).Get(),&token);
}
}
