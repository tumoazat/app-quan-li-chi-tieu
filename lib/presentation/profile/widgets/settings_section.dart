import 'package:flutter/material.dart';

class SettingsItem {
  final dynamic leading; // IconData or String emoji
  final String title;
  final String? value;
  final bool? isToggle;
  final bool? toggleValue;
  final VoidCallback? onTap;
  final Function(bool)? onToggle;

  SettingsItem({
    required this.leading,
    required this.title,
    this.value,
    this.isToggle = false,
    this.toggleValue,
    this.onTap,
    this.onToggle,
  });
}

class SettingsSection extends StatelessWidget {
  final String title;
  final List<SettingsItem> items;

  const SettingsSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 68,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  key: ValueKey(index),
                  onTap: item.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        // Leading icon or emoji
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: item.leading is IconData
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1)
                                : null,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: item.leading is IconData
                              ? Icon(
                                  item.leading as IconData,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : Text(
                                  item.leading as String,
                                  style: const TextStyle(fontSize: 24),
                                ),
                        ),
                        const SizedBox(width: 16),
                        // Title
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        // Trailing
                        if (item.isToggle == true)
                          Switch(
                            value: item.toggleValue ?? false,
                            onChanged: item.onToggle,
                          )
                        else if (item.value != null)
                          Text(
                            item.value!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                          )
                        else
                          Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
