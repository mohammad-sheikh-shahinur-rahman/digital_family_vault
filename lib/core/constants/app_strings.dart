class AppStrings {
  static String get(String key, String lang) {
    final isBn = lang == 'bn';
    switch (key) {
      // Common
      case 'appName': return isBn ? 'ডিজিটাল ফ্যামিলি ভল্ট' : 'Digital Family Vault';
      case 'tagline': return isBn ? 'পরিবারের সব গুরুত্বপূর্ণ কাগজ এক নিরাপদ জায়গায়' : 'All family documents in one secure place';
      case 'documents': return isBn ? 'ডকুমেন্টস' : 'Documents';
      case 'family': return isBn ? 'পরিবার' : 'Family';
      case 'search': return isBn ? 'খুঁজুন' : 'Search';
      case 'settings': return isBn ? 'সেটিংস' : 'Settings';
      case 'emergency': return isBn ? 'জরুরি' : 'Emergency';
      case 'save': return isBn ? 'সংরক্ষণ করুন' : 'Save';
      case 'delete': return isBn ? 'মুছে ফেলুন' : 'Delete';
      case 'cancel': return isBn ? 'বাতিল' : 'Cancel';

      // Dashboard
      case 'familyMembers': return isBn ? 'পরিবারের সদস্যগণ' : 'Family Members';
      case 'noMembersTitle': return isBn ? 'এখনও কোনো সদস্য নেই' : 'No Members Yet';
      case 'noMembersSubtitle': return isBn ? 'শুরু করতে প্রথম সদস্য যোগ করুন' : 'Add the first member to get started';
      case 'addFirstMember': return isBn ? 'প্রথম সদস্য যোগ করুন' : 'Add First Member';
      case 'addMe': return isBn ? 'আমাকে যোগ করুন' : 'Add Me';

      // Add Member Screen
      case 'addMember': return isBn ? 'নতুন সদস্য যোগ করুন' : 'Add New Member';
      case 'fullName': return isBn ? 'পুরো নাম' : 'Full Name';
      case 'fullNameHint': return isBn ? 'যেমন: মোঃ আব্দুল্লাহ' : 'e.g. John Doe';
      case 'nameValidation': return isBn ? 'অনুগ্রহ করে একটি নাম লিখুন' : 'Please enter a name';
      case 'relation': return isBn ? 'সম্পর্ক' : 'Relation';
      case 'relationHint': return isBn ? 'একটি সম্পর্ক নির্বাচন করুন' : 'Select a relation';
      case 'relationValidation': return isBn ? 'অনুগ্রহ করে একটি সম্পর্ক নির্বাচন করুন' : 'Please select a relation';
      case 'saveMember': return isBn ? 'সদস্য সংরক্ষণ করুন' : 'Save Member';

      // Settings Screen
      case 'securityAndPrivacy': return isBn ? 'নিরাপত্তা এবং গোপনীয়তা' : 'Security & Privacy';
      case 'biometricLock': return isBn ? 'বায়োমেট্রিক লক' : 'Biometric Lock';
      case 'biometricLockSubtitle': return isBn ? 'ডিভাইস বায়োমেট্রিক্স দিয়ে আপনার ভল্ট সুরক্ষিত করুন' : 'Secure your vault with device biometrics';
      case 'appearanceAndLanguage': return isBn ? 'অ্যাপের ধরণ এবং ভাষা' : 'Appearance & Language';
      case 'darkMode': return isBn ? 'ডার্ক মোড' : 'Dark Mode';
      case 'darkModeSubtitle': return isBn ? 'অ্যাপের জন্য ডার্ক থিম টগল করুন' : 'Toggle dark theme for the app';
      case 'language': return isBn ? 'ভাষা' : 'Language';
      case 'selectLanguage': return isBn ? 'ভাষা নির্বাচন করুন' : 'Select Language';
      case 'dataManagement': return isBn ? 'ডেটা ম্যানেজমেন্ট' : 'Data Management';
      case 'exportBackup': return isBn ? 'ক্লাউড-রেডি ব্যাকআপ এক্সপোর্ট করুন' : 'Export Cloud-Ready Backup';
      case 'exportBackupSubtitle': return isBn ? 'আপনার সমস্ত ডেটার একটি নিরাপদ জিপ তৈরি করুন' : 'Create a secure ZIP of all your data';
      case 'restoreBackup': return isBn ? 'ব্যাকআপ থেকে রিস্টোর করুন' : 'Restore from Backup';
      case 'restoreBackupSubtitle': return isBn ? 'পূর্ববর্তী এক্সপোর্ট থেকে আপনার ডেটা পুনরুদ্ধার করুন' : 'Recover your data from a previous export';
      case 'wipeData': return isBn ? 'সমস্ত ডেটা মুছে ফেলুন' : 'Wipe All Data';
      case 'wipeDataSubtitle': return isBn ? 'সমস্ত রেকর্ড এবং ফাইল স্থায়ীভাবে মুছুন' : 'Permanently delete all records and files';
      case 'wipeDataConfirmation': return isBn ? 'এটি আপনার সমস্ত নথি, প্রোফাইল এবং সেটিংস স্থায়ীভাবে মুছে ফেলবে। এই পদক্ষেপটি অপরিবর্তনীয়।' : 'This will permanently delete all your documents, profiles, and settings. This action is irreversible.';
      case 'deleteEverything': return isBn ? 'সবকিছু মুছে ফেলুন' : 'Delete Everything';
      case 'supportAndInfo': return isBn ? 'সহায়তা এবং তথ্য' : 'Support & Info';
      case 'about': return isBn ? 'প্রকল্প সম্পর্কে আরও জানুন' : 'Learn more about the project';

      // Auth
      case 'vaultLocked': return isBn ? 'ভল্ট লক করা' : 'Vault Locked';
      case 'authenticate': return isBn ? 'আনলক করতে আঙুলের ছাপ দিন' : 'Use fingerprint to unlock';

      default: return '';
    }
  }

  // Categories (Dynamic)
  static List<String> getCategories(String lang) {
    return lang == 'bn' 
      ? ['NID / পাসপোর্ট', 'জন্ম নিবন্ধন', 'কাবিননামা', 'সার্টিফিকেট', 'মেডিকেল', 'ব্যাংক', 'দলিল', 'অন্যান্য']
      : ['NID / Passport', 'Birth Certificate', 'Marriage Certificate', 'Certificates', 'Medical', 'Bank', 'Property', 'Others'];
  }

  // Relations (Dynamic)
  static List<String> getRelations(String lang) {
    return lang == 'bn'
        ? ['বাবা', 'মা', 'ভাই', 'বোন', 'স্বামী', 'স্ত্রী', 'ছেলে', 'মেয়ে', 'অন্যান্য', 'Me']
        : ['Father', 'Mother', 'Brother', 'Sister', 'Husband', 'Wife', 'Son', 'Daughter', 'Other', 'Me'];
  }
}
