import { StoreService } from './store.js';
import { GeminiService } from './gemini.js';

// State
const state = {
    apiKey: localStorage.getItem('gemini_api_key') || '',
    activeAppId: 'app_a', // 'app_a' or 'app_b'
    apps: {
        app_a: {
            name: localStorage.getItem('appA_name') || 'Visana App',
            id: localStorage.getItem('appA_id') || '1221367995', // Apple ID
            googleFile: null, // File object (not persisted)
            appleReviews: [],
            googleReviews: [],
            insights: { apple: null, google: null }
        },
        app_b: {
            name: localStorage.getItem('appB_name') || 'myPoints',
            id: localStorage.getItem('appB_id') || '6745941827',
            googleFile: null,
            appleReviews: [],
            googleReviews: [],
            insights: { apple: null, google: null }
        }
    }
};

// UI Elements
const ui = {
    titles: {
        header: document.getElementById('header-title'),
        lastUpdated: document.getElementById('last-updated')
    },
    nav: {
        btnAppA: document.getElementById('btn-select-app-a'),
        btnAppB: document.getElementById('btn-select-app-b'),
        labelAppA: document.getElementById('label-app-a-name'),
        labelAppB: document.getElementById('label-app-b-name'),
    },
    modal: {
        el: document.getElementById('config-modal'),
        form: document.getElementById('config-form'),
        openBtn: document.getElementById('btn-open-settings'),
        closeBtns: document.querySelectorAll('.modal-close'),
        inputs: {
            appName: document.getElementById('input-app-name'),
            appId: document.getElementById('input-app-id'),
            googleCsv: document.getElementById('input-google-csv'),
            apiKey: document.getElementById('input-api-key'),
            fileStatus: document.getElementById('google-file-status'),
        },
        tabs: {
            appA: document.getElementById('tab-app-a'),
            appB: document.getElementById('tab-app-b'),
        }
    },
    content: {
        loading: document.getElementById('loading-indicator'),
        dashboard: document.getElementById('dashboard-content'),
        apple: {
            verdict: document.getElementById('apple-verdict-badge'),
            sentiment: document.getElementById('apple-sentiment'),
            pros: document.getElementById('apple-pros'),
            cons: document.getElementById('apple-cons'),
        },
        google: {
            verdict: document.getElementById('google-verdict-badge'),
            sentiment: document.getElementById('google-sentiment'),
            pros: document.getElementById('google-pros'),
            cons: document.getElementById('google-cons'),
        },
        advice: document.getElementById('advice-container'),
        reviews: document.getElementById('reviews-container')
    }
};

// Modal Logic
let configEditingApp = 'app_a'; // Track which app is being edited in modal

function toggleModal(show) {
    if (show) {
        ui.modal.el.classList.remove('opacity-0', 'pointer-events-none');
        document.body.classList.add('modal-active');
        populateModal();
    } else {
        ui.modal.el.classList.add('opacity-0', 'pointer-events-none');
        document.body.classList.remove('modal-active');
    }
}

function switchConfigTab(appKey) {
    configEditingApp = appKey;
    // Style Tabs
    if (appKey === 'app_a') {
        ui.modal.tabs.appA.classList.replace('text-slate-500', 'bg-white');
        ui.modal.tabs.appA.classList.add('shadow-sm');
        ui.modal.tabs.appB.classList.replace('bg-white', 'text-slate-500');
        ui.modal.tabs.appB.classList.remove('shadow-sm');
    } else {
        ui.modal.tabs.appB.classList.replace('text-slate-500', 'bg-white');
        ui.modal.tabs.appB.classList.add('shadow-sm');
        ui.modal.tabs.appA.classList.replace('bg-white', 'text-slate-500');
        ui.modal.tabs.appA.classList.remove('shadow-sm');
    }
    populateModal();
}

function populateModal() {
    const app = state.apps[configEditingApp];
    ui.modal.inputs.appName.value = app.name;
    ui.modal.inputs.appId.value = app.id;
    ui.modal.inputs.apiKey.value = state.apiKey;

    // File input can't be set programmatically, but we can show status
    if (app.googleFile) {
        ui.modal.inputs.fileStatus.innerText = `Ausgewählt: ${app.googleFile.name}`;
    } else {
        ui.modal.inputs.fileStatus.innerText = "Keine Datei gewählt.";
    }
}

// Logic
async function loadData() {
    const currentApp = state.apps[state.activeAppId];

    // Update UI Loading
    ui.content.loading.classList.remove('hidden');
    ui.content.dashboard.classList.add('opacity-50');

    // 1. Fetch & Parse
    // Apple
    if (currentApp.id) {
        currentApp.appleReviews = await StoreService.fetchAppleReviews(currentApp.id);
    }

    // Google (from memory file input)
    if (currentApp.googleFile) {
        currentApp.googleReviews = await StoreService.parseGoogleCsv(currentApp.googleFile);
    }

    // 2. Generate Insights
    if (state.apiKey) {
        if (currentApp.appleReviews.length > 0) {
            currentApp.insights.apple = await GeminiService.generateInsights(currentApp.appleReviews, state.apiKey);
        }
        if (currentApp.googleReviews.length > 0) {
            currentApp.insights.google = await GeminiService.generateInsights(currentApp.googleReviews, state.apiKey);
        }
    }

    // 3. Render
    render();

    ui.content.loading.classList.add('hidden');
    ui.content.dashboard.classList.remove('opacity-50');
    ui.titles.lastUpdated.innerText = `Aktualisiert: ${new Date().toLocaleTimeString()}`;
}

function render() {
    const app = state.apps[state.activeAppId];
    ui.titles.header.innerText = `Analyse: ${app.name}`;
    ui.nav.labelAppA.innerText = state.apps.app_a.name;
    ui.nav.labelAppB.innerText = state.apps.app_b.name;

    // Highlights
    if (state.activeAppId === 'app_a') {
        ui.nav.btnAppA.classList.add('bg-slate-100', 'dark:bg-slate-800', 'font-semibold');
        ui.nav.btnAppB.classList.remove('bg-slate-100', 'dark:bg-slate-800', 'font-semibold');
    } else {
        ui.nav.btnAppB.classList.add('bg-slate-100', 'dark:bg-slate-800', 'font-semibold');
        ui.nav.btnAppA.classList.remove('bg-slate-100', 'dark:bg-slate-800', 'font-semibold');
    }

    // Fill Cards
    renderCard('apple', app.insights.apple);
    renderCard('google', app.insights.google);

    // Fill Advice
    const allAdvice = [
        ...(app.insights.apple?.advice || []),
        ...(app.insights.google?.advice || [])
    ].slice(0, 4);

    ui.content.advice.innerHTML = allAdvice.map(a => `
        <div class="p-6 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl">
            <div class="w-10 h-10 bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 rounded-lg flex items-center justify-center mb-4">
               <span class="material-icons-round">campaign</span>
            </div>
            <h4 class="font-bold mb-2">Handlungsempfehlung</h4>
            <p class="text-sm text-slate-500 leading-relaxed">${a}</p>
        </div>
    `).join('');

    // Fill Reviews
    const recentReviews = [
        ...app.appleReviews,
        ...app.googleReviews
    ].sort((a, b) => b.date - a.date).slice(0, 5);

    ui.content.reviews.innerHTML = recentReviews.map(r => `
        <div class="p-6 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl shadow-sm">
            <div class="flex items-start justify-between mb-4">
                <div class="flex items-center gap-4">
                    <div class="w-10 h-10 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-400">
                        <span class="material-icons-round">person</span>
                    </div>
                    <div>
                        <div class="flex items-center gap-2">
                             <span class="font-bold">${r.author}</span>
                             <span class="text-xs px-2 py-0.5 rounded bg-slate-100 dark:bg-slate-700 text-slate-500 uppercase">${r.source}</span>
                        </div>
                        <div class="flex text-amber-400 text-sm">
                            ${Array(5).fill(0).map((_, i) => `<span class="material-icons-round text-base">${i < r.rating ? 'star' : 'star_border'}</span>`).join('')}
                        </div>
                    </div>
                </div>
                <span class="text-xs text-slate-400 font-medium">${r.date.toLocaleDateString()}</span>
            </div>
            <p class="text-slate-700 dark:text-slate-300 leading-relaxed">${r.content.replace(/\n/g, '<br>')}</p>
        </div>
    `).join('');
}

function renderCard(platform, insights) {
    if (!insights) return; // Keep loading or empty state

    const els = ui.content[platform];
    const isNeg = insights.verdict === 'NEGATIVE';
    const color = isNeg ? 'red' : (insights.verdict === 'POSITIVE' ? 'emerald' : 'gray');

    els.verdict.className = `px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider flex items-center gap-1 bg-${color}-100 dark:bg-${color}-900/30 text-${color}-700 dark:text-${color}-400`;
    els.verdict.innerHTML = `<span class="material-icons-round text-sm">${isNeg ? 'trending_down' : 'trending_up'}</span> ${insights.verdict}`;

    els.sentiment.innerHTML = insights.sentiment;

    els.pros.innerHTML = insights.top_positive.map(p => `
        <li class="flex gap-2 text-slate-600 dark:text-slate-400"><span class="text-emerald-500">•</span> ${p}</li>
    `).join('');

    els.cons.innerHTML = insights.top_negative.map(p => `
        <li class="flex gap-2 text-slate-600 dark:text-slate-400"><span class="text-red-500">•</span> ${p}</li>
    `).join('');
}

// Event Listeners
document.addEventListener('DOMContentLoaded', () => {
    // Nav
    ui.nav.btnAppA.onclick = () => { state.activeAppId = 'app_a'; render(); loadData(); };
    ui.nav.btnAppB.onclick = () => { state.activeAppId = 'app_b'; render(); loadData(); };

    // Modal
    ui.modal.openBtn.onclick = () => toggleModal(true);
    document.getElementById('btn-header-settings').onclick = () => toggleModal(true);
    ui.modal.closeBtns.forEach(btn => btn.onclick = () => toggleModal(false));

    ui.modal.tabs.appA.onclick = () => switchConfigTab('app_a');
    ui.modal.tabs.appB.onclick = () => switchConfigTab('app_b');

    // Config Save
    ui.modal.form.onsubmit = (e) => {
        e.preventDefault();

        // Save to State
        state.apiKey = ui.modal.inputs.apiKey.value;
        const app = state.apps[configEditingApp];
        app.name = ui.modal.inputs.appName.value;
        app.id = ui.modal.inputs.appId.value;

        // Handle File Update
        const fileInput = ui.modal.inputs.googleCsv;
        if (fileInput.files.length > 0) {
            app.googleFile = fileInput.files[0];
        }

        // Persist to LocalStorage
        localStorage.setItem('gemini_api_key', state.apiKey);
        localStorage.setItem(`app${configEditingApp === 'app_a' ? 'A' : 'B'}_name`, app.name);
        localStorage.setItem(`app${configEditingApp === 'app_a' ? 'A' : 'B'}_id`, app.id);

        toggleModal(false);

        // If we edited current app, reload
        if (state.activeAppId === configEditingApp) {
            loadData();
        } else {
            // Just re-render nav labels
            render();
        }
    };

    // Initial Load
    render();
    if (state.apiKey) {
        loadData();
    } else {
        toggleModal(true);
    }
});
