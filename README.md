# Inspectort Pro - אפליקציית בדיקות מקצועית

אפליקציית בדיקות מקצועית לניהול פרויקטים, צילום תמונות, הוספת הערות ויצוא דוחות.

## 🚀 תכונות

- **ממשק רב-לשוני** - תמיכה מלאה בעברית (RTL) ואנגלית
- **מותאם לנייד** - עיצוב Mobile-First עם תמיכה מלאה בנייד
- **PWA** - אפליקציית Web מתקדמת עם יכולות Offline
- **ניהול פרויקטים** - יצירה, עריכה וניהול פרויקטי בדיקה
- **צילום ועריכה** - צילום תמונות ישירות מהמצלמה או העלאה מהגלריה
- **הוספת הערות** - כלי הערות מתקדם עם ציור וטקסט
- **יצוא דוחות** - יצוא דוחות מקצועיים בפורמט PDF ו-Word

## 🛠️ טכנולוגיות

- **Frontend**: HTML5, CSS3, JavaScript (ES6+)
- **Styling**: CSS Grid/Flexbox, CSS Variables
- **PWA**: Service Worker, Web App Manifest
- **Icons**: SVG Icons
- **Fonts**: Heebo (עברית), System Fonts

## 📁 מבנה הפרויקט

```
inspect-pro/
├── index.html              # עמוד ראשי
├── manifest.json           # PWA Manifest
├── service-worker.js       # Service Worker
├── css/
│   └── styles.css         # CSS ראשי
├── js/
│   └── app.js             # JavaScript ראשי
├── assets/
│   ├── icons/             # אייקונים
│   └── images/            # תמונות
└── docs/
    └── inspectort_instructions.md
```

## 🚀 התחלה מהירה

1. **שכפל את הפרויקט**:
   ```bash
   git clone https://github.com/your-username/inspectort-pro.git
   cd inspectort-pro
   ```

2. **הפעל שרת מקומי**:
   ```bash
   # עם Python
   python -m http.server 8000
   
   # עם Node.js
   npx http-server
   
   # עם PHP
   php -S localhost:8000
   ```

3. **פתח בדפדפן**:
   ```
   http://localhost:8000
   ```

## 📱 התקנה כ-PWA

1. פתח את האפליקציה בדפדפן נייד
2. לחץ על תפריט הדפדפן
3. בחר "הוסף למסך הבית" או "Install App"
4. האפליקציה תופיע כאפליקציה מקומית

## 🔧 פיתוח

### דרישות מערכת
- דפדפן מודרני עם תמיכה ב-ES6+
- שרת HTTP (לא ניתן לפתוח ישירות מהקובץ)

### מצבי פיתוח

**מצב פיתוח**:
- פתח את ה-Developer Tools
- בחר Console לראות לוגים
- בחר Application > Service Workers לניהול SW

**מצב בדיקה**:
- בדיקת responsive design
- בדיקת offline functionality
- בדיקת PWA features

## 📄 רישיון

MIT License - ראה את קובץ LICENSE לפרטים מלאים.

## 🤝 תרומה

תרומות מתקבלות בברכה! אנא:

1. צור Fork של הפרויקט
2. צור Branch חדש (`git checkout -b feature/amazing-feature`)
3. Commit את השינויים (`git commit -m 'Add amazing feature'`)
4. Push ל-Branch (`git push origin feature/amazing-feature`)
5. פתח Pull Request

## 📞 יצירת קשר

- **מייל**: support@inspectort-pro.com
- **GitHub**: [Issues](https://github.com/your-username/inspectort-pro/issues)

## 🔄 מצב פיתוח

הפרויקט נמצא בפיתוח פעיל. גרסה נוכחית: **v1.0.0**

### שלבי פיתוח:

- [x] **Step 1**: מבנה בסיסי + PWA
- [ ] **Step 2**: אימות משתמשים
- [ ] **Step 3**: ניהול פרויקטים
- [ ] **Step 4**: צילום תמונות
- [ ] **Step 5**: הוספת הערות
- [ ] **Step 6**: יצוא דוחות

---

**Inspectort Pro** - הפתרון המקצועי לבדיקות ודיווח דיגיטלי 🚀 