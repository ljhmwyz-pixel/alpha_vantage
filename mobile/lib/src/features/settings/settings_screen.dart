import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_config.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          tooltip: '返回',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          '设置',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: '服务器配置'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.dns_outlined,
                iconColor: const Color(0xFF3B82F6),
                title: 'API 服务器地址',
                subtitle: AppConfig.apiBaseUrl,
                onTap: () {},
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.cloud_outlined,
                iconColor: const Color(0xFF10B981),
                title: '数据源',
                subtitle: 'Yahoo Finance',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: '用户信息'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.person_outline,
                iconColor: const Color(0xFF8B5CF6),
                title: '用户ID',
                subtitle: AppConfig.demoUserId,
                trailing: IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已复制到剪贴板'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: '应用设置'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                iconColor: const Color(0xFFF59E0B),
                title: '价格提醒',
                subtitle: '已开启',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                ),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.palette_outlined,
                iconColor: const Color(0xFFEC4899),
                title: '主题',
                subtitle: '跟随系统',
                onTap: () {},
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.refresh_outlined,
                iconColor: const Color(0xFF6366F1),
                title: '自动刷新',
                subtitle: '每 30 秒',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: '关于'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                iconColor: const Color(0xFF64748B),
                title: '版本',
                subtitle: '1.0.0',
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.code_outlined,
                iconColor: const Color(0xFF64748B),
                title: '开源协议',
                subtitle: 'MIT License',
                onTap: () {},
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.code,
                iconColor: const Color(0xFF64748B),
                title: '源代码',
                subtitle: 'GitHub',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Alpha Vantage Monitor v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: trailing ??
          (onTap != null ? const Icon(Icons.chevron_right, size: 20) : null),
      onTap: onTap,
    );
  }
}
