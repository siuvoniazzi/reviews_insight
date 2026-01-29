const { onCall } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const { Storage } = require("@google-cloud/storage");
const { parse } = require("csv-parse/sync");
const jwt = require("jsonwebtoken");
const fetch = require("node-fetch");
const { GoogleGenerativeAI } = require("@google/generative-ai");

admin.initializeApp();

// Secrets
const applePrivateKey = defineSecret("APPLE_PRIVATE_KEY");
const appleIssuerId = defineSecret("APPLE_ISSUER_ID");
const appleKeyId = defineSecret("APPLE_KEY_ID");
const googleGcsBucket = defineSecret("GOOGLE_GCS_BUCKET");
const geminiApiKey = defineSecret("GEMINI_API_KEY");

// 1. App Store Connect API Helper
const fetchAppleReviewsInternal = async (appId) => {
    if (!applePrivateKey.value() || !appleIssuerId.value() || !appleKeyId.value()) {
        console.warn("Apple secrets not configured.");
        return [];
    }

    // Generate JWT
    const token = jwt.sign({}, applePrivateKey.value(), {
        algorithm: "ES256",
        expiresIn: "20m",
        issuer: appleIssuerId.value(),
        keyid: appleKeyId.value(),
        audience: "appstoreconnect-v1",
    });

    const url = `https://api.appstoreconnect.apple.com/v1/apps/${appId}/customerReviews?sort=-createdDate&limit=50`;

    try {
        const response = await fetch(url, {
            headers: { Authorization: `Bearer ${token}` },
        });

        if (!response.ok) {
            console.error("Apple API Error:", await response.text());
            return [];
        }

        const data = await response.json();
        return data.data.map((item) => ({
            author: item.attributes.reviewerNickname,
            rating: parseFloat(item.attributes.rating),
            content: item.attributes.body,
            date: item.attributes.createdDate,
            source: "apple",
        }));
    } catch (e) {
        console.error("Fetch Apple Reviews Failed:", e);
        return [];
    }
};

// 2. Google Play GCS Helper
const fetchGoogleReviewsInternal = async () => {
    const bucketName = googleGcsBucket.value();
    if (!bucketName) {
        console.warn("Google GCS Bucket secret not configured.");
        return [];
    }

    const storage = new Storage();
    const bucket = storage.bucket(bucketName);

    // Find the latest CSV file in 'reviews/' prefix (assuming structure)
    // For simplicity, we search for files with 'reviews' in name and take latest
    try {
        const [files] = await bucket.getFiles({ prefix: 'reviews/' });
        if (files.length === 0) return [];

        // Sort by time created desc
        files.sort((a, b) => new Date(b.metadata.timeCreated) - new Date(a.metadata.timeCreated));
        const latestFile = files[0];

        const [content] = await latestFile.download();
        const records = parse(content, {
            columns: true,
            skip_empty_lines: true,
            relax_quotes: true
        });

        // Map CSV fields to Review model
        // Play Store CSV headers usually: Package Name, App Version Code, Reviewer Language, Device, Review Submit Date and Time, Review Submit Date and Time in UTC, Star Rating, Review Title, Review Text, Developer Reply Date and Time, Developer Reply Text, Review Link, Reviewer Name (some fields deprecated)
        return records.map(r => ({
            author: "Google User", // PII often removed in exports
            rating: parseFloat(r['Star Rating'] || "0"),
            content: r['Review Text'] || "",
            date: r['Review Submit Date and Time'] || new Date().toISOString(),
            source: "google"
        })).slice(0, 50); // Limit to 50
    } catch (e) {
        console.error("GCS Fetch Failed:", e);
        return [];
    }
};

// 3. Gemini Helper
const generateInsightsInternal = async (reviews) => {
    if (!geminiApiKey.value()) return "Gemini API Key missing.";

    const genAI = new GoogleGenerativeAI(geminiApiKey.value());
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

    const prompt = `Analyze these reviews and provide: 1. Sentiment Summary. 2. Top 3 Pros. 3. Top 3 Cons. 4. Actionable Advice. \n\nReviews:\n${reviews.map(r => `- [${r.source}] ${r.rating}/5: ${r.content}`).join("\n")}`;

    try {
        const result = await model.generateContent(prompt);
        return result.response.text();
    } catch (e) {
        console.error("Gemini Error:", e);
        return "Failed to generate insights.";
    }
};


// 4. Main Endpoint
exports.fetchReviews = onCall({ secrets: [applePrivateKey, appleIssuerId, appleKeyId, googleGcsBucket, geminiApiKey] }, async (request) => {
    const { appId } = request.data;

    // Parallel fetch
    const [appleReviews, googleReviews] = await Promise.all([
        fetchAppleReviewsInternal(appId), // Only fetch apple if appId provided? Or always? Assuming appId implies Apple ID.
        fetchGoogleReviewsInternal()     // Google is bucket based, disjoint from appId param usually
    ]);

    const allReviews = [...appleReviews, ...googleReviews];

    // Determine if we should generate insights here or separate call.
    // Let's do it here for "One Click" experience.
    const insights = await generateInsightsInternal(allReviews);

    return {
        reviews: allReviews,
        insights: insights
    };
});
