import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momentum/features/diet/presentation/widgets/diet_ai_tab.dart';
import 'package:momentum/features/diet/presentation/widgets/diet_journal_tab.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/providers/ai_providers.dart';
import '../../../core/services/settings_service.dart';

// DietScreen now becomes a lightweight shell
class DietScreen extends ConsumerStatefulWidget {
  const DietScreen({super.key});

  @override
  ConsumerState<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends ConsumerState<DietScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      resizeToAvoidBottomInset: false, // Important to prevent body resizing when keyboard opens for tabs
      appBar: AppBar(
        title: const Text('Diet & Nutrition'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Journal'),
            Tab(text: 'AI Assistant'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear_history') {
                _showClearConfirmation();
              } else if (value == 'change_model') {
                _showModelSelectionDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'change_model',
                child: Row(
                  children: [
                    Icon(Icons.psychology_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Change AI Model'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_history',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear Chat History'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,

        children: const [
          DietJournalTab(),
          DietAiTab(),
        ],
      ),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat History?'),
        content: const Text('This will permanently delete all messages in this chat.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearChat();
            },
            child: Text('Clear', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearChat() async {
    final db = ref.read(appDatabaseProvider);
    await db.clearDietChatHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat history cleared')),
      );
    }
  }

  void _showModelSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final modelAsync = ref.watch(geminiModelProvider);
          final currentModel = modelAsync.valueOrNull;
          
          return AlertDialog(
            title: const Text('Select Gemini Model'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModelDialogItem(ref, 'Gemini 3.0 Flash', 'gemini-3.0-flash', currentModel),
                    _buildModelDialogItem(ref, 'Gemini 3.0 Pro Preview', 'gemini-3.0-pro-preview', currentModel),
                    _buildModelDialogItem(ref, 'Gemini 2.0 Flash', 'gemini-2.0-flash', currentModel),
                    _buildModelDialogItem(ref, 'Gemini 2.0 Flash-Lite Preview', 'gemini-2.0-flash-lite-preview-02-05', currentModel),
                    _buildModelDialogItem(ref, 'Gemini 2.0 Pro Exp', 'gemini-2.0-pro-experimental-02-05', currentModel),
                    _buildModelDialogItem(ref, 'Gemini 1.5 Pro', 'gemini-1.5-pro', currentModel),
                    _buildModelDialogItem(ref, 'Gemini 1.5 Flash', 'gemini-1.5-flash', currentModel),
                    _buildModelDialogItem(ref, 'Gemini 1.5 Flash-8B', 'gemini-1.5-flash-8b', currentModel),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModelDialogItem(WidgetRef ref, String label, String value, String? current) {
    final isSelected = value == current;
    return ListTile(
      leading: Icon(
        Icons.auto_awesome, 
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
        size: 20,
      ),
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : null, color: isSelected ? Theme.of(context).colorScheme.primary : null)),
      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary, size: 18) : null,
      onTap: () {
        ref.read(geminiModelProvider.notifier).setModel(value);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Model set to \$label')));
      },
    );
  }

}
