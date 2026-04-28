import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/client_view_cubit/client_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/client/client_card_widget.dart';
import '../../widgets/client/client_header.dart';
import '../../widgets/client/client_search_header.dart';

class ClientScreen extends StatelessWidget {
  const ClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loaderService = LoaderService();
    final GlobalKey<SearchBarWidgetState> searchBarKey =
        GlobalKey<SearchBarWidgetState>();

    // Fetch clients when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = AppDI.clientCubit;
      if (cubit.state.clients.isEmpty &&
          cubit.state.processState != ProcessState.loading) {
        cubit.getClients();
      }
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AppScaffold(
        useGradient: true,
        gradientBegin: Alignment.topCenter,
        gradientEnd: Alignment.bottomCenter,
        showDrawer: false,
        appBar: const AppBarWidget(hasNotifications: true),
        showBottomNav: false,
        child: BlocConsumer<ClientCubit, ClientState>(
          listener: (context, state) {
            if (state.processState == ProcessState.error &&
                state.errorMessage != null &&
                state.errorMessage!.isNotEmpty) {
              showSnackBar(context, state.errorMessage!, isSuccess: false);
            }
            // Only show delete success messages here (create/update are handled in dialogs)
            if (state.successMessage != null &&
                state.successMessage!.isNotEmpty &&
                state.successMessage!.toLowerCase().contains('deleted')) {
              showSnackBar(context, state.successMessage!, isSuccess: true);
              // Clear success message after showing
              AppDI.clientCubit.clearError();
            }
            if (state.processState == ProcessState.loading) {
              loaderService.showLoader();
            } else if (state.processState == ProcessState.done ||
                state.processState == ProcessState.error) {
              loaderService.hideLoader();
            }
          },
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                final cubit = AppDI.clientCubit;
                await cubit.refreshClients();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ClientHeader(),
                    const SizedBox(height: 10),
                    ClientSearchHeader(
                      searchBarKey: searchBarKey,
                      clientSection: true,
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child:
                          state.clients.isEmpty &&
                              state.processState != ProcessState.loading
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                child: Center(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        Assets.noClientImg,
                                        height: 120,
                                        width: 120,
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        TextHelper.noClientTitle,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineLarge,
                                      ),
                                      const SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20.0,
                                        ),
                                        child: Text(
                                          TextHelper.noClientText,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium!.color,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 12),
                              itemCount: state.clients.length,
                              // Add cacheExtent to keep more items in memory during scroll
                              cacheExtent: 500,
                              itemBuilder: (context, index) {
                                final client = state.clients[index];
                                return ClientCardWidget(
                                  // Stable key prevents widget recreation on scroll
                                  key: ValueKey(client.id ?? client.clientId ?? index),
                                  client: client,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
