import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/models/filter_params.dart';
import '../../cubits/notification/notification_cubit.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  late final ScrollController _scrollController;
  final _searchCtrl = TextEditingController();
  int _pageLimit = 20;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLoad());
  }

  void _initLoad() {
    if (!mounted) return;
    final h = MediaQuery.of(context).size.height;
    _pageLimit = (h / 80).ceil() + 3;
    context.read<NotificationCubit>().load(FilterParams(limit: _pageLimit));
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<NotificationCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notificaciones'),
            actions: [
              if (state is NotificationLoaded &&
                  state.notifications.isNotEmpty) ...[
                TextButton(
                  onPressed: () =>
                      context.read<NotificationCubit>().markAllRead(),
                  child: const Text('Marcar todo leído'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: 'Borrar todas',
                  onPressed: () async {
                    final confirm = await showConfirmDialog(
                      context,
                      title: 'Borrar notificaciones',
                      message:
                          '¿Eliminar todas las notificaciones?',
                      confirmLabel: 'Borrar',
                      isDangerous: true,
                    );
                    if (confirm == true && context.mounted) {
                      context.read<NotificationCubit>().clearAll();
                    }
                  },
                ),
              ],
            ],
          ),
          body: SafeArea(top: false, child: () {
            if (state is NotificationLoading ||
                state is NotificationInitial) {
              return const LoadingIndicator();
            }
            if (state is NotificationError) {
              return ErrorView(
                message: state.message,
                onRetry: () =>
                    context.read<NotificationCubit>().load(),
              );
            }
            if (state is NotificationLoaded) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Buscar notificación…',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  context
                                      .read<NotificationCubit>()
                                      .search('');
                                },
                              )
                            : null,
                      ),
                      onChanged: (q) =>
                          context.read<NotificationCubit>().search(q),
                    ),
                  ),
                  if (state.isSearching)
                    const LinearProgressIndicator(minHeight: 2),
                  Expanded(
                    child: state.notifications.isEmpty
                        ? EmptyView(
                            message: _searchCtrl.text.isNotEmpty
                                ? 'Sin resultados para "${_searchCtrl.text}"'
                                : 'No tienes notificaciones',
                            icon: Icons.notifications_none,
                          )
                        : RefreshIndicator(
                      onRefresh: () {
                        _searchCtrl.clear();
                        return context
                            .read<NotificationCubit>()
                            .load(FilterParams(limit: _pageLimit));
                      },
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: state.notifications.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, i) {
                    final n = state.notifications[i];
                    return Dismissible(
                      key: ValueKey(n.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: Theme.of(context).colorScheme.error,
                        child: const Icon(Icons.delete,
                            color: Colors.white),
                      ),
                      onDismissed: (_) =>
                          context.read<NotificationCubit>().delete(n.id),
                      child: ListTile(
                        tileColor: n.isRead
                            ? null
                            : Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.3),
                        leading: CircleAvatar(
                          backgroundColor: n.isRead
                              ? Theme.of(context).colorScheme.surfaceContainerHighest
                              : Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.notifications,
                            color: n.isRead
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(n.message,
                            style: TextStyle(
                                fontWeight: n.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold)),
                        subtitle: Text(DateFormat('dd/MM/yy HH:mm')
                            .format(DateTime.tryParse(n.createdAt ?? '') ?? DateTime.now())),
                        onTap: n.isRead
                            ? null
                            : () => context
                                .read<NotificationCubit>()
                                .markRead(n.id),
                      ),
                    );
                        },
                      ),
                    ),
                  ),
                  if (state.isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              );
            }
            return const SizedBox();
          }()),
        );
      },
    );
  }
}
