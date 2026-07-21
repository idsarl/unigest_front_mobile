# Unigest - Application de Gestion Scolaire

Une application mobile Flutter pour la gestion scolaire, permettant aux parents, aux élèves et aux enseignants de suivre les notes, l'emploi du temps, les absences et les notifications.

### Interface Enseignant
L'interface enseignant (branche `feature_enseignant`) comprend :
- Gestion des appels et présences
- Saisie et consultation des notes
- Emploi du temps
- Messagerie avec pièces jointes
- Mode hors ligne avec synchronisation automatique (Hive + file d'attente)

## 🚀 Fonctionnalités

### Système d'Authentification
- Page de connexion avec design moderne (inscription non disponible sur cette page)
- Animation fluides et interface utilisateur intuitive
- Connexion via API backend Spring Boot (port 5200)
- Les parents et enseignants reçoivent des identifiants pour se connecter
- Les élèves peuvent s'inscrire via un mécanisme séparé (à implémenter)
- Comptes de test pour faciliter les tests :
  - Parent : `parent@test.com` → Accès interface parent
  - Élève : `student@test.com` → Accès interface élève

### Interface Élève
L'interface élève comprend 5 onglets principaux :

1. **Notes**
   - Affichage de la moyenne du trimestre le plus récent
   - Cartes de moyennes par trimestre (T1, T2, T3)
   - Liste détaillée des notes avec :
     - Matière
     - Type (devoir, interrogation, examen)
     - Note obtenue / note maximale
     - Coefficient
     - Date
     - Commentaire optionnel

2. **Emploi du temps**
   - Affichage des cours par jour de la semaine
   - Informations détaillées : matière, professeur, salle, horaires

3. **Alertes (Notifications)**
   - Liste des notifications avec gestion de l'état lu/non lu
   - Filtrage par type (alerte, info, succès, avertissement)
   - Bouton pour marquer toutes comme lues
   - Design moderne avec icônes colorées

4. **Absences**
   - Liste des absences avec détails
   - Type d'absence (justifiée, non justifiée)
   - Raison et justification

5. **Profil**
   - Informations personnelles de l'élève
   - Numéro étudiant, email, téléphone, adresse
   - Bouton de déconnexion

### Interface Parent
L'interface parent permet de :

1. **Accueil**
   - Liste des enfants avec statistiques
   - Cartes animées avec avatars colorés
   - Navigation vers les détails de chaque enfant

2. **Détails de l'enfant**
   - Onglets pour les notes, emploi du temps, absences, notifications
   - Affichage détaillé similaire à l'interface élève

3. **Notifications**
   - Gestion des notifications liées aux enfants

## 🛠️ Stack Technique

- **Framework** : Flutter
- **State Management** : GetX
- **Architecture** : MVC (Model-View-Controller)
- **Langage** : Dart

## 📁 Structure du Projet

```
lib/
├── core/
│   ├── state_management/
│   │   └── getx_helpers.dart       # BaseController pour la gestion d'état
│   └── theme/
│       ├── app_colors.dart         # Définition des couleurs
│       └── app_theme.dart          # Thème de l'application
├── features/
│   ├── auth/
│   │   ├── controllers/
│   │   │   └── auth_controller.dart # Gestion de l'authentification
│   │   └── views/
│   │       └── login_view.dart     # Page de connexion/inscription
│   ├── parent/
│   │   ├── controllers/
│   │   │   ├── parent_home_controller.dart
│   │   │   └── child_details_controller.dart
│   │   └── views/
│   │       ├── parent_main_view.dart
│   │       ├── parent_home_view.dart
│   │       ├── child_details_view.dart
│   │       └── parent_notifications_view.dart
│   └── student/
│       ├── controllers/
│       │   └── student_home_controller.dart
│       └── views/
│           └── student_home_view.dart
├── models/
│   ├── note_model.dart             # Modèle des notes avec champ trimestre
│   ├── emploi_model.dart           # Modèle de l'emploi du temps
│   ├── absence_model.dart          # Modèle des absences
│   ├── notification_model.dart     # Modèle des notifications
│   └── child_model.dart            # Modèle des enfants
├── widgets/
│   └── common/
│       └── custom_bottom_nav_bar.dart # Barre de navigation personnalisée
├── app.dart                        # Configuration des routes GetX
└── main.dart                       # Point d'entrée de l'application
```

## 🎨 Design

L'application utilise un design moderne avec :
- Dégradés de couleurs
- Ombres et effets de profondeur
- Animations fluides (TweenAnimationBuilder)
- Coins arrondis
- Palette de couleurs cohérente (AppColors)
- Interface responsive

## 📊 Système de Notes par Trimestre

Le système de notes différencie les moyennes par trimestre :
- Chaque note possède un champ `trimestre` (1, 2 ou 3)
- Calcul automatique des moyennes par trimestre
- Affichage de la moyenne du trimestre le plus récent dans le cadre principal
- Cartes individuelles pour chaque trimestre

## 🚦 Installation et Exécution

### Prérequis
- Flutter SDK (version 3.0 ou supérieure)
- Dart SDK
- Xcode (pour iOS) ou Android Studio (pour Android)

### Étapes d'installation

1. Cloner le repository :
```bash
git clone <repository-url>
cd unigest_front_mobile
```

2. Installer les dépendances :
```bash
flutter pub get
```

3. Lancer l'application :
```bash
flutter run
```

### Comptes de Test

Pour tester l'application :
- **Parent** : Email `parent@test.com`, Mot de passe : (n'importe quoi)
- **Élève** : Email `student@test.com`, Mot de passe : (n'importe quoi)

## 🔧 Configuration

Les routes sont configurées dans `lib/app.dart` :
- `/auth` : Page d'authentification (route initiale)
- `/parent-home` : Accueil parent
- `/student-home` : Accueil élève
- `/child-details` : Détails d'un enfant

## 📝 Notes de Développement

### Points à Améliorer
- Intégration avec un backend réel pour l'authentification
- API pour récupérer les données réelles (notes, emploi du temps, etc.)
- Persistance locale des données
- Tests unitaires et tests d'intégration
- Gestion des erreurs plus robuste
- Internationalisation (i18n)

### Conventions de Code
- Utilisation de GetX pour la gestion d'état
- Séparation MVC (Model-View-Controller)
- Utilisation de BaseController pour les contrôleurs
- Widgets réutilisables dans le dossier `widgets/common`
- Observables GetX (Rx) pour les données réactives

## � Explication du Code (Pour Débutants)

### 1. Architecture MVC (Model-View-Controller)

Le projet suit le pattern MVC qui sépare l'application en trois parties :

**Model (Modèle)** : Contient les données et la logique métier
```dart
// Exemple : NoteModel
class NoteModel {
  final String id;
  final String subject;
  final double value;
  final int trimestre;
  
  NoteModel({
    required this.id,
    required this.subject,
    required this.value,
    required this.trimestre,
  });
}
```

**View (Vue)** : L'interface utilisateur (ce que l'utilisateur voit)
```dart
// Exemple : StudentHomeView
class StudentHomeView extends GetView<StudentHomeController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildNotesTab()),
        ],
      ),
    );
  }
}
```

**Controller (Contrôleur)** : Gère la logique et les données entre le modèle et la vue
```dart
// Exemple : StudentHomeController
class StudentHomeController extends BaseController {
  final RxList<NoteModel> notes = <NoteModel>[].obs;
  
  Future<void> loadData() async {
    setLoading(true);
    // Charger les données...
    setLoading(false);
  }
}
```

### 2. GetX - Gestion d'État

GetX est utilisé pour gérer l'état de l'application de manière réactive.

**Observables (Rx)** : Variables qui notifient automatiquement la vue quand elles changent
```dart
// Variable réactive
final RxString email = ''.obs;
final RxBool isLoading = false.obs;
final RxList<NoteModel> notes = <NoteModel>[].obs;

// Accéder à la valeur
print(email.value); // Affiche la valeur actuelle
```

**Obx** : Widget qui se reconstruit automatiquement quand un observable change
```dart
Obx(() => Text(
  controller.email.value,
  style: TextStyle(color: AppColors.primary),
))
// Quand controller.email change, le Text se met à jour automatiquement
```

**GetView** : Widget qui a accès automatiquement au contrôleur
```dart
class StudentHomeView extends GetView<StudentHomeController> {
  // controller est disponible automatiquement
  @override
  Widget build(BuildContext context) {
    return Text(controller.moyenneGenerale.value.toString());
  }
}
```

### 3. BaseController

Classe de base pour tous les contrôleurs avec des fonctionnalités communes :
```dart
class BaseController extends GetxController {
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  
  void setLoading(bool value) {
    _isLoading.value = value;
  }
}

// Utilisation
class StudentHomeController extends BaseController {
  Future<void> loadData() async {
    setLoading(true); // Affiche un indicateur de chargement
    await Future.delayed(Duration(seconds: 2));
    setLoading(false); // Cache l'indicateur
  }
}
```

### 4. Navigation avec GetX

Navigation simplifiée entre les pages :
```dart
// Naviguer vers une page
Get.toNamed('/student-home');

// Naviguer et remplacer toutes les pages (pour le login)
Get.offAllNamed('/parent-home');

// Retourner à la page précédente
Get.back();
```

### 5. Configuration des Routes

Les routes sont définies dans `app.dart` :
```dart
GetPage(
  name: '/auth',
  page: () => const LoginView(),
  binding: BindingsBuilder(() {
    Get.lazyPut(() => AuthController());
  }),
),
```
- `name` : URL de la route
- `page` : Widget à afficher
- `binding` : Initialise le contrôleur associé

### 6. Animations avec TweenAnimationBuilder

Animations fluides pour les transitions :
```dart
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0.0, end: 1.0), // Animation de 0 à 1
  duration: Duration(milliseconds: 800),
  builder: (context, value, child) {
    return Transform.scale(
      scale: 0.8 + (0.2 * value), // Échelle de 0.8 à 1.0
      child: Opacity(
        opacity: value, // Opacité de 0 à 1
        child: child,
      ),
    );
  },
)
```

### 7. Structure d'une Vue

Exemple de structure d'une vue avec GetX :
```dart
class ExampleView extends GetView<ExampleController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Exemple')),
      body: Obx(() {
        if (controller.isLoading) {
          return CircularProgressIndicator();
        }
        return ListView(
          children: controller.items.map((item) => 
            ListTile(title: Text(item.name))
          ).toList(),
        );
      }),
    );
  }
}
```

### 8. Structure d'un Contrôleur

Exemple de contrôleur avec GetX :
```dart
class ExampleController extends BaseController {
  final RxList<ItemModel> items = <ItemModel>[].obs;
  final RxString selectedItem = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadItems(); // Appelé automatiquement à l'initialisation
  }
  
  Future<void> loadItems() async {
    setLoading(true);
    try {
      // Charger les données depuis une API
      items.value = await apiService.getItems();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }
  
  void selectItem(String id) {
    selectedItem.value = id;
  }
}
```

### 9. Bonnes Pratiques

- **Séparation des responsabilités** : Chaque classe a un rôle unique
- **Utilisation de const** : Pour les widgets qui ne changent pas
- **Widgets réutilisables** : Créer des widgets personnalisés pour éviter la répétition
- **Gestion des erreurs** : Toujours utiliser try-catch pour les opérations asynchrones
- **Nettoyage** : Disposer des controllers quand ils ne sont plus nécessaires

### 10. Flux de Données

```
User Action → Controller → API/Service → Model
                ↓
            Update Observable
                ↓
            Obx detects change
                ↓
            View rebuilds
                ↓
            UI updates
```

## �📄 Licence

Ce projet est développé à des fins éducatives.

## 🤝 Contribution

Les contributions sont les bienvenues. Pour les suggestions d'amélioration ou les bugs, veuillez ouvrir une issue.
