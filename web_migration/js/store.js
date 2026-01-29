/**
 * Service to handle review data fetching and parsing.
 */
export const StoreService = {

    /**
     * Fetch reviews from Apple RSS Feed.
     * @param {string} appId - The Apple App ID.
     * @param {string} country - Country code (default 'ch').
     * @returns {Promise<Array>} List of reviews.
     */
    async fetchAppleReviews(appId, country = 'ch') {
        const url = `https://itunes.apple.com/${country}/rss/customerreviews/id=${appId}/sortBy=mostRecent/json`;
        console.log(`Fetching from: ${url}`);

        try {
            const response = await fetch(url);
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);

            const data = await response.json();
            const feed = data.feed;

            if (!feed || !feed.entry) return [];

            const entries = Array.isArray(feed.entry) ? feed.entry : [feed.entry];

            return entries.map(entry => {
                const author = entry.author?.name?.label || 'Anonymous';
                const title = entry.title?.label || '';
                const content = entry.content?.label || '';
                const rating = parseFloat(entry['im:rating']?.label || '0');

                // Apple RSS 'updated' field example: 2023-10-27T02:00:00-07:00
                const dateStr = entry.updated?.label;
                const date = dateStr ? new Date(dateStr) : new Date();

                return {
                    source: 'apple',
                    author,
                    rating,
                    content: title ? `${title}\n${content}` : content,
                    date
                };
            });

        } catch (error) {
            console.error("Error fetching Apple reviews:", error);
            return []; // Fail gracefully
        }
    },

    /**
     * Parse Google Play CSV file content.
     * Handles UTF-16LE BOM and other CSV oddities typically found in Play Console exports.
     * @param {File} file - The file object from input.
     * @returns {Promise<Array>} List of reviews.
     */
    async parseGoogleCsv(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();

            reader.onload = (e) => {
                try {
                    const buffer = e.target.result; // ArrayBuffer
                    let content = '';

                    // 1. Detect encoding (UTF-16LE BOM)
                    const uint8 = new Uint8Array(buffer);
                    if (uint8[0] === 0xFF && uint8[1] === 0xFE) {
                        // Decode UTF-16LE
                        const decoder = new TextDecoder('utf-16le');
                        content = decoder.decode(uint8.subarray(2));
                    } else {
                        // Fallback UTF-8 / Latin1 (TextDecoder defaults to utf-8)
                        const decoder = new TextDecoder('utf-8');
                        content = decoder.decode(uint8);
                    }

                    // 2. CSV Parsing (Basic implementation to avoid heavy libs)
                    // We need to handle quoted fields containing newlines.
                    const rows = this.parseCSVString(content);
                    if (rows.length === 0) return resolve([]);

                    // 3. Map Headers
                    const headers = rows[0].map(h => h.trim().toLowerCase());

                    const ratingIdx = headers.findIndex(h => h.includes('star rating'));
                    const textIdx = headers.findIndex(h => h.includes('review text'));
                    const titleIdx = headers.findIndex(h => h.includes('review title'));
                    const dateIdx = headers.findIndex(h => h.includes('submit date'));

                    if (ratingIdx === -1) {
                        console.warn("Invalid Google CSV: Missing Star Rating");
                        return resolve([]);
                    }

                    const reviews = [];
                    // Skip header
                    for (let i = 1; i < rows.length; i++) {
                        const row = rows[i];
                        if (row.length <= ratingIdx) continue;

                        const rating = parseFloat(row[ratingIdx]) || 0;
                        let body = '';
                        if (textIdx !== -1 && row[textIdx]) body = row[textIdx];

                        if (titleIdx !== -1 && row[titleIdx]) {
                            const title = row[titleIdx];
                            body = body ? `${title}\n${body}` : title;
                        }

                        const dateStr = (dateIdx !== -1 && row[dateIdx]) ? row[dateIdx] : null;

                        reviews.push({
                            source: 'google',
                            author: 'Google User', // Usually anonymized
                            rating,
                            content: body || '[No written review]',
                            date: dateStr ? new Date(dateStr) : new Date()
                        });
                    }

                    resolve(reviews);

                } catch (err) {
                    console.error("CSV Parse Error:", err);
                    resolve([]);
                }
            };

            reader.onerror = () => reject(reader.error);
            reader.readAsArrayBuffer(file);
        });
    },

    // Simple CSV Parser that handles quoted strings
    parseCSVString(str) {
        const arr = [];
        let quote = false;
        let row = [];
        let col = '';

        for (let c = 0; c < str.length; c++) {
            let cc = str[c];
            let nc = str[c + 1];

            if (cc === '"') {
                if (quote && nc === '"') { col += '"'; c++; } // Escaped quote
                else { quote = !quote; }
            } else if (cc === ',' && !quote) {
                row.push(col); col = '';
            } else if ((cc === '\r' || cc === '\n') && !quote) {
                row.push(col); col = '';
                if (row.length > 0) arr.push(row);
                row = [];
                if (cc === '\r' && nc === '\n') c++; // Skip \n after \r
            } else {
                col += cc;
            }
        }
        if (row.length > 0 || col.length > 0) {
            row.push(col); arr.push(row);
        }
        return arr;
    }
};
