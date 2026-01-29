# Review Insight - Web Version

This is a standalone HTML/JavaScript application for analyzing app store reviews using Google's Gemini AI.

## Features

✅ **Apple App Store Reviews** - Fetches reviews from iTunes RSS feed  
✅ **Google Play Reviews** - Upload CSV exports from Play Console  
✅ **Gemini AI Analysis** - Generates sentiment analysis, pros/cons, and recommendations  
✅ **Multi-App Support** - Configure and switch between two different apps  
✅ **Modern UI** - Responsive design with dark mode support  

## Getting Started

### Prerequisites

- A modern web browser (Chrome, Firefox, Edge, Safari)
- Gemini API Key (get one from [https://aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey))
- Apple App ID (find it in the App Store URL, e.g., `1221367995` from `apps.apple.com/app/id1221367995`)
- (Optional) Google Play CSV export

### How to Use

1. **Open the Application**
   - Simply double-click `index.html` in your file browser
   - Or right-click and select "Open with" → your browser
   - Or drag `index.html` into your browser window

2. **Initial Configuration**
   - On first launch, the Settings dialog will appear automatically
   - Enter your **Gemini API Key**
   - Configure **App A** (default: Visana App)
     - App Name
     - Apple App ID
     - (Optional) Upload Google Play CSV file
   - Click **"Speichern & Analysieren"** to save and start analysis

3. **Switch Between Apps**
   - Use the sidebar to switch between App A and App B
   - Each app maintains its own configuration
   - Click the settings icon to reconfigure any app

4. **View Results**
   - **Sentiment Overview** - AI-generated summary for each platform
   - **Pros & Cons** - Top 3 positive and negative points
   - **Recommendations** - Actionable advice based on reviews
   - **Individual Reviews** - Most recent reviews from both platforms

## How to Get Google Play CSV

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Navigate to **Reviews** → **All reviews**
4. Click **Download reviews** (top right)
5. Select CSV format and download
6. Upload the CSV file in the Settings dialog

## Data Privacy

- All data is processed **locally in your browser**
- Review data is sent only to Google's Gemini API for analysis
- Your API key is stored in browser localStorage (not sent anywhere except to authenticate with Gemini)
- No backend server or database is used

## Troubleshooting

**Modal won't open**: Check browser console (F12) for JavaScript errors

**Apple reviews not loading**: 
- Verify the App ID is correct
- Some apps may not have public reviews available
- Check if the app is available in the selected country (default: Switzerland 'ch')

**Google CSV not parsing**:
- Ensure you've downloaded the CSV from Play Console (not a third-party tool)
- The CSV should have columns like "Star Rating", "Review Text", etc.

**Gemini analysis fails**:
- Verify your API key is correct
- Check you have available quota in your Google AI Studio account
- Make sure you have at least some reviews loaded

## Technical Details

- **No build step required** - pure HTML/JS/CSS
- **ES6 Modules** - uses native JavaScript modules
- **Tailwind CSS** - via CDN for styling
- **Google Generative AI SDK** - via ESM CDN (esm.run)
- **LocalStorage** - for persisting settings

## File Structure

```
web_migration/
├── index.html          # Main application UI
└── js/
    ├── app.js          # Application controller
    ├── store.js        # Apple RSS & Google CSV parser
    └── gemini.js       # Gemini AI service
```

## Browser Compatibility

- ✅ Chrome 90+
- ✅ Firefox 88+
- ✅ Edge 90+
- ✅ Safari 14+

(Requires ES6 Module support and Import Maps)
