// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class AiBusinessDiscovery {
  static const groups =
      <String, ({List<String> categories, List<String> words})>{
        'enhancements': (
          categories: [
            'enhancements',
            'leave',
            'electricity',
            'campus_network',
          ],
          words: [
            '增强插件',
            '增强功能',
            '插件功能',
            'enhancements',
            'enhancement plugins',
          ],
        ),
        'campus_network': (
          categories: ['campus_network'],
          words: ['校园网', '校园宽带', '上网认证', '网络认证', '宽带登录', 'campus network'],
        ),
        'mutual_evaluation': (
          categories: ['mutual_evaluation'],
          words: ['学生互评', '同学互评', '快速互评', '互评', 'mutual evaluation'],
        ),
        'online_learning': (
          categories: ['online_learning'],
          words: ['学习通网页版', '学习通', '超星', '网课', 'chaoxing', 'online learning'],
        ),
        'notices': (
          categories: ['notices'],
          words: ['通知', '公告', '消息通知', '竞赛', '比赛', '讲座', '报名', 'notices'],
        ),
        'classrooms': (
          categories: ['classrooms'],
          words: [
            '空教室',
            '空闲教室',
            '教室查询',
            '查教室',
            '自习',
            '自修',
            'study room',
            'classrooms',
          ],
        ),
        'calendar': (
          categories: ['calendar', 'schedule'],
          words: [
            '日历',
            '课表',
            '课程安排',
            '上什么课',
            '早八',
            '哪天有空',
            '明天安排',
            'calendar',
            'schedule',
          ],
        ),
        'school_calendar': (
          categories: ['school_calendar', 'notices'],
          words: ['校历', '校运会', '运动会', '放假', '假期', '开学', 'school calendar'],
        ),
        'scores': (
          categories: ['scores'],
          words: ['成绩', '绩点', '均分', '分数', '挂科', 'gpa', 'scores'],
        ),
        'curriculum': (
          categories: ['curriculum'],
          words: ['培养方案', '毕业要求', '学分要求', '必修', '选修', 'curriculum'],
        ),
        'leave': (
          categories: ['smart_work', 'leave'],
          words: ['请假', '假条', '休假', 'leave'],
        ),
        'diary': (
          categories: ['diary', 'calendar'],
          words: ['日记', '今日笺', '今日笔记', 'diary'],
        ),
        'electricity': (
          categories: ['electricity', 'enhancements'],
          words: ['电费', '电量', '剩余度数', '宿舍用电', 'electricity'],
        ),
        'apps': (
          categories: ['mobile_apps', 'apps'],
          words: ['移动应用', '交大邮箱', '学校邮箱', '网络教学', '学习通', 'mobile apps'],
        ),
      };

  static bool matches(String query, String text, {String? category}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final searchable = text.toLowerCase();
    if (q.split(RegExp(r'\s+')).every(searchable.contains)) return true;
    return groups.values.any(
      (group) =>
          group.words.any(q.contains) &&
          (group.categories.contains(category) ||
              group.words.any(searchable.contains)),
    );
  }

  static bool inCategory(String filter, String category, {String text = ''}) {
    final q = filter.trim().toLowerCase();
    if (q.isEmpty || q == category.toLowerCase()) return true;
    return groups.values.any(
      (group) =>
          group.words.contains(q) &&
          (group.categories.contains(category) ||
              (text.isNotEmpty &&
                  group.words.any(text.toLowerCase().contains))),
    );
  }
}
