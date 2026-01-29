import { GoogleGenerativeAI } from "@google/generative-ai";

export const GeminiService = {
    async generateInsights(reviews, apiKey) {
        if (!reviews || reviews.length === 0) return this.emptyResult();
        if (!apiKey) return this.errorResult("API Key missing");

        try {
            const genAI = new GoogleGenerativeAI(apiKey);
            const model = genAI.getGenerativeModel({
                model: "gemini-3-flash-preview", // Using flash model as per original code
                generationConfig: { responseMimeType: "application/json" }
            });

            const prompt = `
            Analysiere die folgenden App-Bewertungen und gib das Ergebnis NUR als valides JSON zurück.
            Erwartetes JSON-Format:
            {
                "sentiment": "Zusammenfassung der Stimmung (max 2 Sätze in Deutsch)",
                "top_positive": ["Punkt 1", "Punkt 2", "Punkt 3"],
                "top_negative": ["Punkt 1", "Punkt 2", "Punkt 3"],
                "advice": ["Rat 1", "Rat 2", "Rat 3"],
                "verdict": "POSITIVE" oder "NEGATIVE" oder "NEUTRAL"
            }
            
            Bewertungen:
            ${reviews.slice(0, 50).map(r => `- [${r.source}] rating: ${r.rating}, content: ${r.content}`).join('\n')}
            `;

            const result = await model.generateContent(prompt);
            const text = result.response.text();

            // Basic cleanup if markdown fences exist
            const cleanText = text.replace(/```json/g, '').replace(/```/g, '').trim();
            return JSON.parse(cleanText);

        } catch (e) {
            console.error("Gemini Error:", e);
            return this.errorResult(e.message);
        }
    },

    emptyResult() {
        return {
            sentiment: "Keine Daten.",
            top_positive: [],
            top_negative: [],
            advice: [],
            verdict: "NEUTRAL"
        };
    },

    errorResult(msg) {
        return {
            sentiment: `Fehler bei der Analyse: ${msg}`,
            top_positive: [],
            top_negative: [],
            advice: [],
            verdict: "NEUTRAL"
        };
    }
};
