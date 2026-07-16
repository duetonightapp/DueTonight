# DueTonight - Assignment Tracker App

## 1. Project Overview

**Project Name:** DueTonight  
**Project Type:** Cross-platform Mobile Application (Flutter)  
**Core Functionality:** A centralized assignment and task management app that helps college students track all their assignments, projects, and tasks from various sources with deadlines and submission modes.

---

## 2. Technology Stack & Choices

| Component | Choice |
|-----------|--------|
| **Framework** | Flutter 3.x |
| **State Management** | Riverpod (flutter_riverpod) |
| **Backend/Auth** | Supabase (Auth + Database) |
| **Authentication** | Google Sign-In |
| **Architecture** | Clean Architecture (Presentation → Domain → Data) |
| **Platform** | Android (primary), iOS (secondary) |

### Key Dependencies
- `supabase_flutter` - Supabase client
- `flutter_riverpod` - State management
- `google_sign_in` - Google authentication
- `go_router` - Navigation
- `intl` - Date formatting
- `flutter_local_notifications` - Deadline reminders

---

## 3. Feature List

### Authentication Module
- [x] Google Sign-In authentication
- [x] Persistent session management
- [x] User profile (name, email, avatar)
- [x] Sign-out functionality

### Assignment Management
- [ ] Add new assignments with:
  - Title, description
  - Subject/course
  - Deadline (date & time)
  - Submission mode (Online/Offline)
  - Platform (HackerRank, NPTEL, Moodle, etc.)
  - Priority level (High, Medium, Low)
- [ ] View all assignments (sorted by deadline)
- [ ] Filter assignments by status (Pending, Completed, Overdue)
- [ ] Mark assignments as complete
- [ ] Edit/Delete assignments

### Organization
- [ ] Create/join batches/classes
- [ ] View assignments by subject
- [ ] Dashboard with upcoming deadlines

### Notifications
- [ ] Deadline reminders (1 day before, on due day)
- [ ] Overdue notifications

---

## 4. UI/UX Design Direction

### Visual Style
- **Design System:** Material Design 3
- **Theme:** Modern, clean, student-friendly
- **Color Scheme:**
  - Primary: Deep Purple (#6750A4)
  - Secondary: Teal accent for deadlines
  - Urgency indicators: Red (overdue), Orange (urgent), Green (safe)

### Layout Approach
- **Navigation:** Bottom navigation bar with 3 tabs:
  1. Dashboard (home)
  2. Assignments (list view)
  3. Profile/Settings
- **Cards:** Assignment cards with color-coded urgency
- **Forms:** Clean modal bottom sheets for adding assignments

### Key Screens
1. **Splash Screen** - App branding, auto-login check
2. **Auth Screen** - Google sign-in button
3. **Dashboard** - Quick overview of upcoming deadlines
4. **Assignments List** - Filterable, sortable list
5. **Add/Edit Assignment** - Modal form
6. **Profile** - User info, batch info, settings

---

## 5. Database Schema (Supabase)

### Tables

**profiles**
- id (uuid, primary key)
- email (text)
- full_name (text)
- avatar_url (text)
- batch_id (uuid, foreign key)
- created_at (timestamp)

**batches**
- id (uuid, primary key)
- name (text)
- college_name (text)
- created_at (timestamp)

**assignments**
- id (uuid, primary key)
- user_id (uuid, foreign key → profiles)
- title (text)
- description (text)
- subject (text)
- deadline (timestamp)
- submission_mode (text: 'online' | 'offline')
- platform (text)
- priority (text: 'high' | 'medium' | 'low')
- is_completed (boolean)
- created_at (timestamp)
- updated_at (timestamp)

---

## 6. Project Structure

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
├── data/
│   ├── models/
│   ├── repositories/
│   └── datasources/
├── domain/
│   ├── entities/
│   └── repositories/
├── presentation/
│   ├── screens/
│   ├── widgets/
│   └── providers/
└── routes/
```