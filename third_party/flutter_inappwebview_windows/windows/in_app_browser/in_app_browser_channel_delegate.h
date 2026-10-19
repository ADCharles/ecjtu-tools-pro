#ifndef FLUTTER_INAPPWEBVIEW_PLUGIN_IN_APP_BROWSER_CHANNEL_DELEGATE_H_
#define FLUTTER_INAPPWEBVIEW_PLUGIN_IN_APP_BROWSER_CHANNEL_DELEGATE_H_

#include <flutter/method_channel.h>
#include <flutter/standard_message_codec.h>

#include "../types/channel_delegate.h"

namespace flutter_inappwebview_plugin
{
  class InAppBrowserChannelDelegate : public ChannelDelegate
  {
  public:
    InAppBrowserChannelDelegate(const std::string& id, flutter::BinaryMessenger* messenger);
    ~InAppBrowserChannelDelegate();

    // The browser instance this delegate is bound to; resolved by the
    // manager right after construction so per-instance method calls
    // (getBounds / loadUrl) can act on the window.
    InAppBrowser* browser = nullptr;

    void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    void onBrowserCreated() const;
    void onMenuItemClicked(int id) const;
    void onExit() const;
  };
}

#endif //FLUTTER_INAPPWEBVIEW_PLUGIN_IN_APP_BROWSER_CHANNEL_DELEGATE_H_
