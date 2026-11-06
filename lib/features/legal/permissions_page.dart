import 'package:flutter/material.dart';

import '../../core/animations/animations.dart';
import '../../core/session/legal_store.dart';
import 'legal_content.dart';
import 'legal_document_page.dart';

/// Écran post-inscription : demande les permissions système avec une
/// justification claire pour chacune (principe de loyauté et de
/// transparence exigé par le Livre V de la loi camerounaise 2010/012).
class PermissionsPage extends StatelessWidget {
  const PermissionsPage({super.key, this.onNext});

  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = PermissionsScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Permissions',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // On autorise le skip : rien ici n'est obligatoire.
              (onNext ??
                  () => Navigator.of(context).pushReplacement(
                    FadeSlideRoute<void>(page: _after(context)),
                  ))();
            },
            child: const Text('Plus tard'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          FadeSlideIn(
            child: Text(
              'Ce qu\'Educoach peut te demander',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: Text(
              'Aucune permission n\'est obligatoire. Chaque demande '
              'n\'est envoyée au système que lorsque la fonction est '
              'utilisée. Tu peux tout refuser ou revenir ici depuis '
              'le Profil.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Stagger(
            children: [
              for (final p in appPermissions) _PermissionTile(permission: p),
            ],
          ),
          const SizedBox(height: 20),
          _LegalLinks(),
          const SizedBox(height: 24),
          ListenableBuilder(
            listenable: store,
            builder: (context, _) => FilledButton.icon(
              onPressed: () {
                (onNext ??
                    () => Navigator.of(context).pushReplacement(
                      FadeSlideRoute<void>(page: _after(context)),
                    ))();
              },
              icon: const Icon(Icons.check_rounded),
              label: Text(
                store.grantedCount == 0
                    ? 'Continuer sans permission'
                    : 'Continuer · ${store.grantedCount} accordée(s)',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _after(BuildContext context) {
    // Après les permissions, on redirige vers le sélecteur de filière.
    // Import direct pour éviter un cycle.
    // ignore: avoid_dynamic_calls
    return _PickerBridge.build(context);
  }
}

/// Petit pont pour éviter l'import circulaire : la page cible est
/// résolue au runtime via les routes nommées.
class _PickerBridge {
  static Widget build(BuildContext context) => Builder(
    builder: (context) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/pick-filiere');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    },
  );
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({required this.permission});

  final AppPermission permission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = PermissionsScope.of(context);
    final c = permission.color ?? theme.colorScheme.primary;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final granted = store.isGranted(permission.id);
        return AnimatedContainer(
          duration: Motion.normal,
          curve: Motion.emphasized,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: granted
                  ? c.withValues(alpha: 0.55)
                  : theme.colorScheme.outlineVariant,
              width: granted ? 1.6 : 1,
            ),
            boxShadow: granted
                ? [
                    BoxShadow(
                      color: c.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: Motion.normal,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: granted ? 0.24 : 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(permission.icon, color: c),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      permission.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      permission.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Switch(
                value: granted,
                onChanged: (v) => store.grant(permission.id, v),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LegalLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.gavel_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Cadre juridique',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Conformément à la loi n° 2010/012 (Livre V) relative à la '
            'cybersécurité et à la prévention de la cybercriminalité, '
            'tu conserves un droit d\'accès, de rectification, '
            'd\'opposition et de retrait du consentement. Réclamation '
            'auprès de l\'ART.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  FadeSlideRoute<void>(
                    page: LegalDocumentPage(document: termsDocument),
                  ),
                ),
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('Conditions générales'),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  FadeSlideRoute<void>(
                    page: LegalDocumentPage(document: privacyDocument),
                  ),
                ),
                icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                label: const Text('Politique de confidentialité'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
