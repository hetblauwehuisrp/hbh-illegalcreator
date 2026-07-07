const app = document.getElementById('app');
const listEl = document.getElementById('activityList');
const panel = document.getElementById('panel');
const editorTitle = document.getElementById('editorTitle');
const editorSub = document.getElementById('editorSub');
const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'hbh-illegalcreator';
const modalEl = document.getElementById('nuiModal');
const modalTitle = document.getElementById('modalTitle');
const modalMessage = document.getElementById('modalMessage');
const modalInputWrap = document.getElementById('modalInputWrap');
const modalInputLabel = document.getElementById('modalInputLabel');
const modalInput = document.getElementById('modalInput');
const modalOk = document.getElementById('modalOk');
const modalCancel = document.getElementById('modalCancel');
let modalResolver = null;
let modalMode = 'confirm';

let state = {
    open: false,
    activities: [],
    config: {},
    selected: null,
    tab: 'basis',
    search: '',
    stepPage: 0,
    stepsPerPage: 3,
    collapsedSteps: {}
};

const post = (name, data = {}) => fetch(`https://${resource}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
}).then(r => r.json()).catch(() => ({ ok: false, message: 'NUI fout.' }));

const clone = obj => JSON.parse(JSON.stringify(obj || {}));
const n = (v, fallback = 0) => Number.isFinite(Number(v)) ? Number(v) : fallback;
const b = v => v === true || v === 'true' || v === 1 || v === '1' || v === 'on';
const esc = v => String(v ?? '').replace(/[&<>'"]/g, s => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#039;', '"': '&quot;' }[s]));

function closeNuiModal(value) {
    if (!modalEl) return;
    modalEl.classList.add('hidden');
    modalEl.setAttribute('aria-hidden', 'true');
    const resolver = modalResolver;
    modalResolver = null;
    if (resolver) resolver(value);
}

function openNuiModal(options = {}) {
    if (!modalEl) return Promise.resolve(null);
    if (modalResolver) closeNuiModal(null);

    modalMode = options.mode || 'confirm';
    modalTitle.textContent = options.title || 'Bevestigen';
    modalMessage.textContent = options.message || 'Weet je het zeker?';
    modalOk.textContent = options.okText || 'Bevestigen';
    modalCancel.textContent = options.cancelText || 'Annuleren';

    if (modalMode === 'prompt') {
        modalInputWrap.classList.remove('hidden');
        modalInputLabel.textContent = options.inputLabel || 'Naam';
        modalInput.value = options.defaultValue || '';
    } else {
        modalInputWrap.classList.add('hidden');
        modalInput.value = '';
    }

    modalEl.classList.remove('hidden');
    modalEl.setAttribute('aria-hidden', 'false');

    setTimeout(() => {
        if (modalMode === 'prompt') modalInput.focus();
        else modalOk.focus();
    }, 0);

    return new Promise(resolve => {
        modalResolver = resolve;
    });
}

function nuiConfirm(message, title = 'Bevestigen') {
    return openNuiModal({ mode: 'confirm', title, message, okText: 'Ja, verwijderen', cancelText: 'Annuleren' });
}

function nuiPrompt(message, defaultValue = '', title = 'Invoeren') {
    return openNuiModal({ mode: 'prompt', title, message, defaultValue, inputLabel: 'Naam', okText: 'Opslaan', cancelText: 'Annuleren' });
}

function defaultActivity() {
    const d = state.config.defaults || {};
    return {
        id: null,
        name: 'Nieuwe activiteit',
        category: 'custom',
        coords: { x: 0, y: 0, z: 0, h: 0 },
        target_radius: d.TargetRadius || 1.8,
        max_distance: d.MaxDistance || 3.0,
        required_items: [],
        rewards: [],
        action_points: [],
        animation: { preset: 'none' },
        min_police: d.MinPolice || 0,
        min_police_grade: d.MinPoliceGrade || 0,
        cooldown: d.Cooldown || 900,
        duration: d.Duration || 7500,
        police_blip_time: d.PoliceBlipTime || 60,
        enabled: true,
        alert_police: false,
        police_blip: false,
        progressbar: true,
        minigame: false,
        minigame_difficulty: d.MinigameDifficulty || 'normal',
        blip: false,
        marker: true,
        settings: {
            waypoint: true,
            onePlayerOnly: false,
            alertOn: 'start',
            alertStep: 1,
            wash: {
                input: 'black_money',
                output: 'money',
                percentage: 50,
                maxPercentage: 50,
                fee: 0,
                minAmount: 10000,
                maxAmount: 100000,
                route: {
                    enabled: true,
                    pedModel: 's_m_m_highsec_01',
                    pedScenario: 'WORLD_HUMAN_CLIPBOARD',
                    vehicleModel: 'speedo',
                    vehicleSpawn: { x: 0, y: 0, z: 0, h: 0 },
                    minStops: 2,
                    maxStops: 4,
                    randomDuration: true,
                    duration: 10000,
                    randomDurationMin: 8000,
                    randomDurationMax: 18000,
                    ownVehicleUpgradeEnabled: true,
                    ownVehicleUpgradePrice: 200000,
                    ownVehicleUpgradeAccount: 'bank'
                },
                jobs: []
            },
            drugs: {
                drugType: 'coke',
                mode: 'process',
                inputItem: 'coke_leaf',
                inputAmount: 1,
                outputItem: 'coke_powder',
                outputMin: 1,
                outputMax: 1,
                pickRewardItem: 'coke_leaf',
                pickRewardMin: 1,
                pickRewardMax: 3,
                requiredItem: '',
                requiredAmount: 1,
                removeRequired: true,
                duration: 7500,
                minigame: false,
                difficulty: 'normal',
                animation: 'drug_process'
            },
            police: {
                chance: 100,
                text: 'Verdachte illegale activiteit gemeld in de buurt.',
                radius: 75,
                sprite: 161,
                color: 1,
                scale: 1.2
            },
            visual_builder: {
                enabled: false,
                blocks: []
            }
        }
    };
}


function normalizeCategory(category) {
    return category === 'drugs_verpakken' ? 'drugs_verwerken' : category;
}

function builderAllowed(category) {
    category = normalizeCategory(category);
    return ['drugs_verwerken', 'illegale_crafting', 'lab_activiteit', 'custom'].includes(category);
}

function drugPageAllowed(category) {
    category = normalizeCategory(category);
    return ['drugs_plukken', 'drugs_verwerken'].includes(category);
}

function visibleTabsFor(a) {
    const tabs = ['basis', 'stappen', 'items', 'politie', 'instellingen'];
    if (a && drugPageAllowed(a.category)) tabs.splice(3, 0, 'drugs');
    if (a && builderAllowed(a.category)) tabs.splice(4, 0, 'bouwer');
    if (a && a.category === 'witwassen') tabs.splice(4, 0, 'witwas');
    return tabs;
}

function ensureAllowedTab() {
    const a = state.selected ? selectedOrDefault() : null;
    const allowed = visibleTabsFor(a);
    if (!allowed.includes(state.tab)) state.tab = 'basis';
}

function builderTemplates() {
    return [
        { type: 'required_item', label: 'Benodigd item', icon: '📦', defaults: { name: 'coke_leaf', amount: 1, remove: false } },
        { type: 'remove_item', label: 'Item verwijderen', icon: '➖', defaults: { name: 'coke_leaf', amount: 1, remove: true } },
        { type: 'reward_item', label: 'Reward item', icon: '➕', defaults: { name: 'coke_bag', min: 1, max: 1, chance: 100, guaranteed: true } },
        { type: 'reward_money', label: 'Geld reward', icon: '💶', defaults: { account: 'black_money', min: 100, max: 250, chance: 100, guaranteed: true } },
        { type: 'progress', label: 'Wachttijd', icon: '⏱', defaults: { duration: 7500, label: 'Verwerken' } },
        { type: 'minigame', label: 'Minigame', icon: '🎮', defaults: { enabled: false, difficulty: 'normal' } },
        { type: 'animation', label: 'Animatie', icon: '🧍', defaults: { preset: 'drug_process' } },
        { type: 'police', label: 'Politie melding', icon: '🚨', defaults: { enabled: false, chance: 25 } }
    ];
}

function getBuilder(a) {
    a.settings = a.settings || {};
    a.settings.visual_builder = a.settings.visual_builder || { enabled: false, blocks: [] };
    a.settings.visual_builder.blocks = a.settings.visual_builder.blocks || [];
    return a.settings.visual_builder;
}

function addBuilderBlock(type) {
    const a = selectedOrDefault();
    const template = builderTemplates().find(t => t.type === type);
    if (!template) return;
    const builder = getBuilder(a);
    builder.blocks.push({ id: Date.now() + '_' + Math.floor(Math.random() * 9999), type, ...clone(template.defaults) });
    builder.enabled = true;
    renderPanel();
}

function builderBlockTitle(block) {
    const t = builderTemplates().find(x => x.type === block.type);
    return t ? `${t.icon} ${t.label}` : 'Blok';
}

function categoryLabel(value) {
    const normalized = normalizeCategory(value);
    return (state.config.categories || []).find(c => c.value === normalized)?.label || normalized || 'Custom';
}

function actionLabel(value) {
    return (state.config.actionTypes || []).find(c => c.value === value)?.label || value || 'Custom actie';
}

function selectedOrDefault() {
    if (!state.selected) state.selected = defaultActivity();
    state.selected.settings = state.selected.settings || {};
    if (state.selected.category === 'drugs_verpakken') {
        state.selected.category = 'drugs_verwerken';
        state.selected.settings.drugs = state.selected.settings.drugs || {};
        state.selected.settings.drugs.mode = state.selected.settings.drugs.mode || 'package';
    }
    const defs = defaultActivity();
    state.selected.settings.wash = state.selected.settings.wash || clone(defs.settings.wash);
    state.selected.settings.wash.route = state.selected.settings.wash.route || clone(defs.settings.wash.route);
    state.selected.settings.wash.route.vehicleSpawn = state.selected.settings.wash.route.vehicleSpawn || clone(defs.settings.wash.route.vehicleSpawn);
    state.selected.settings.wash.jobs = state.selected.settings.wash.jobs || [];
    state.selected.settings.police = state.selected.settings.police || clone(defs.settings.police);
    state.selected.settings.drugs = state.selected.settings.drugs || clone(defs.settings.drugs);
    state.selected.settings.visual_builder = state.selected.settings.visual_builder || clone(defs.settings.visual_builder);
    state.selected.settings.visual_builder.blocks = state.selected.settings.visual_builder.blocks || [];
    state.selected.required_items = state.selected.required_items || [];
    state.selected.rewards = state.selected.rewards || [];
    state.selected.action_points = state.selected.action_points || [];
    state.selected.animation = state.selected.animation || { preset: 'none' };
    return state.selected;
}

function renderList() {
    const q = state.search.toLowerCase();
    const filtered = (state.activities || []).filter(a => !q || String(a.name).toLowerCase().includes(q) || String(a.category).toLowerCase().includes(q));
    listEl.innerHTML = filtered.map(a => `
        <div class="activity-card ${state.selected && state.selected.id === a.id ? 'active' : ''}" data-select="${a.id}">
            <h4>${esc(a.name)}</h4>
            <p>${esc(categoryLabel(a.category))}</p>
            <div class="badges">
                <span class="badge ${a.enabled ? 'on' : 'off'}">${a.enabled ? 'Aan' : 'Uit'}</span>
                <span class="badge">${(a.action_points || []).length} stappen</span>
                <span class="badge">${a.min_police || 0} politie</span>
            </div>
        </div>
    `).join('') || '<p class="muted">Geen activiteiten gevonden.</p>';
}

function selectActivity(id) {
    const found = (state.activities || []).find(a => Number(a.id) === Number(id));
    state.selected = clone(found || defaultActivity());
    state.stepPage = 0;
    state.collapsedSteps = {};
    render();
}

function categoryOptions(value) {
    const normalized = normalizeCategory(value);
    return (state.config.categories || []).map(c => `<option value="${esc(c.value)}" ${c.value === normalized ? 'selected' : ''}>${esc(c.label)}</option>`).join('');
}

function actionOptions(value) {
    return (state.config.actionTypes || []).map(c => `<option value="${esc(c.value)}" ${c.value === value ? 'selected' : ''}>${esc(c.label)}</option>`).join('');
}

function presetOptions(value) {
    const presets = state.config.animationPresets || {};
    return Object.entries(presets).map(([key, preset]) => `<option value="${esc(key)}" ${key === value ? 'selected' : ''}>${esc(preset.label || key)}</option>`).join('');
}

function difficultyOptions(value) {
    return ['easy', 'normal', 'hard', 'expert'].map(d => `<option value="${d}" ${d === value ? 'selected' : ''}>${d}</option>`).join('');
}

function coordFields(prefix, coords, attrName, labelPrefix = '') {
    coords = coords || { x: 0, y: 0, z: 0, h: 0 };
    return `
        <div class="field"><label>${labelPrefix}X</label><input ${attrName}="x" type="number" step="0.0001" value="${coords.x || 0}"></div>
        <div class="field"><label>${labelPrefix}Y</label><input ${attrName}="y" type="number" step="0.0001" value="${coords.y || 0}"></div>
        <div class="field"><label>${labelPrefix}Z</label><input ${attrName}="z" type="number" step="0.0001" value="${coords.z || 0}"></div>
        <div class="field"><label>Heading</label><input ${attrName}="h" type="number" step="0.0001" value="${coords.h || 0}"></div>
    `;
}

function renderBasis(a) {
    const isWash = a.category === 'witwassen';
    const wash = a.settings?.wash || {};
    const route = wash.route || {};
    route.vehicleSpawn = route.vehicleSpawn || { x: 0, y: 0, z: 0, h: 0 };

    const startTitle = isWash ? 'Starten locatie' : 'Startlocatie';
    const startButton = isWash ? 'Gebruik huidige locatie voor starten' : 'Gebruik huidige locatie';

    return `
        <div class="card">
            <div class="card-title">
                <h3>Basisgegevens</h3>
            </div>
            <div class="grid">
                <div class="field"><label>Naam</label><input data-field="name" value="${esc(a.name)}"></div>
                <div class="field"><label>Categorie</label><select data-field="category">${categoryOptions(a.category)}</select></div>
                <div class="field"><label>Target radius</label><input data-field="target_radius" type="number" step="0.1" value="${a.target_radius}"></div>
                <div class="field"><label>Max afstand</label><input data-field="max_distance" type="number" step="0.1" value="${a.max_distance}"></div>
                <div class="field"><label>Cooldown seconden</label><input data-field="cooldown" type="number" value="${a.cooldown}"></div>
                <div class="field"><label>Duur ms</label><input data-field="duration" type="number" value="${a.duration}"></div>
            </div>
        </div>
        <div class="card">
            <div class="card-title">
                <h3>${startTitle}</h3>
                <button class="small" data-action="use-current-start">${startButton}</button>
            </div>
            <div class="grid">
                ${coordFields('start', a.coords || {}, 'data-coord')}
            </div>
        </div>
        ${isWash ? `
            <div class="card">
                <div class="card-title">
                    <h3>Auto spawn locatie</h3>
                    <button class="small" data-action="use-current-vehicle-spawn">Gebruik huidige locatie voor auto spawn</button>
                </div>
                <div class="grid">
                    ${coordFields('vehicle', route.vehicleSpawn, 'data-wash-route-coord')}
                </div>
            </div>
        ` : ''}
        <div class="card">
            <div class="grid three">
                ${switchHtml('enabled', 'Activiteit aan/uit', a.enabled)}
                ${switchHtml('blip', 'Blip aan/uit', a.blip)}
                ${switchHtml('marker', 'Marker aan/uit', a.marker)}
                ${switchHtml('progressbar', 'Progressbar aan/uit', a.progressbar)}
                ${switchHtml('minigame', 'Minigame aan/uit', a.minigame)}
                <div class="field"><label>Minigame moeilijkheid</label><select data-field="minigame_difficulty">${difficultyOptions(a.minigame_difficulty)}</select></div>
            </div>
        </div>
        <div class="card">
            <div class="card-title"><h3>Animatie preset</h3><button class="small" data-action="preview-main-animation">Preview</button></div>
            <div class="grid">
                <div class="field"><label>Preset</label><select data-animation="preset">${presetOptions(a.animation?.preset || 'none')}</select></div>
                <div class="field"><label>Scenario</label><input data-animation="scenario" value="${esc(a.animation?.scenario || '')}" placeholder="WORLD_HUMAN_CLIPBOARD"></div>
                <div class="field"><label>Dict</label><input data-animation="dict" value="${esc(a.animation?.dict || '')}"></div>
                <div class="field"><label>Clip</label><input data-animation="clip" value="${esc(a.animation?.clip || '')}"></div>
            </div>
        </div>
    `;
}

function switchHtml(field, label, checked) {
    return `<label class="switch-row"><span>${esc(label)}</span><input type="checkbox" data-field="${field}" ${checked ? 'checked' : ''}></label>`;
}

function renderItems(a) {
    return `
        <div class="card">
            <div class="card-title"><h3>Benodigde items bij start</h3><button class="small" data-action="add-required">+ Toevoegen</button></div>
            <div class="quick">${quickButtons('required')}</div>
            <div class="list-stack">${a.required_items.map((r, i) => itemRow('required', r, i)).join('') || '<p class="muted">Geen required items ingesteld.</p>'}</div>
        </div>
        <div class="card">
            <div class="card-title"><h3>Rewards aan einde</h3><button class="small" data-action="add-reward">+ Toevoegen</button></div>
            <div class="quick">${quickButtons('reward')}</div>
            <div class="list-stack">${a.rewards.map((r, i) => rewardRow(r, i)).join('') || '<p class="muted">Geen rewards ingesteld.</p>'}</div>
        </div>
    `;
}

function quickButtons(kind) {
    return (state.config.quickItems || []).map(q => `<button class="small" data-quick="${kind}" data-type="${q.type}" data-name="${q.name}">${esc(q.label)}</button>`).join('');
}

function itemRow(kind, item, i) {
    return `
        <div class="item-row">
            <div class="field"><label>Naam</label><input data-${kind}="${i}" data-prop="name" value="${esc(item.name || '')}"></div>
            <div class="field"><label>Type</label><select data-${kind}="${i}" data-prop="type"><option value="item" ${item.type !== 'account' ? 'selected' : ''}>Item</option><option value="account" ${item.type === 'account' ? 'selected' : ''}>Geld/account</option></select></div>
            <div class="field"><label>Aantal</label><input data-${kind}="${i}" data-prop="amount" type="number" value="${item.amount || item.count || 1}"></div>
            <label class="switch-row"><span>Verwijderen</span><input data-${kind}="${i}" data-prop="remove" type="checkbox" ${item.remove ? 'checked' : ''}></label>
            <div></div>
            <button class="danger small" data-remove-${kind}="${i}">X</button>
        </div>
    `;
}

function rewardRow(reward, i) {
    return `
        <div class="item-row">
            <div class="field"><label>Naam</label><input data-reward="${i}" data-prop="name" value="${esc(reward.name || '')}"></div>
            <div class="field"><label>Type</label><select data-reward="${i}" data-prop="type"><option value="item" ${reward.type !== 'account' ? 'selected' : ''}>Item</option><option value="account" ${reward.type === 'account' ? 'selected' : ''}>Geld/account</option></select></div>
            <div class="field"><label>Min</label><input data-reward="${i}" data-prop="min" type="number" value="${reward.min || reward.amount || 1}"></div>
            <div class="field"><label>Max</label><input data-reward="${i}" data-prop="max" type="number" value="${reward.max || reward.amount || 1}"></div>
            <div class="field"><label>Kans %</label><input data-reward="${i}" data-prop="chance" type="number" value="${reward.chance ?? 100}"></div>
            <button class="danger small" data-remove-reward="${i}">X</button>
        </div>
    `;
}

function renderStappen(a) {
    const steps = a.action_points || [];
    const isWash = a.category === 'witwassen';
    const title = isWash ? 'Klop locaties' : 'Actiepunten';
    const addLabel = isWash ? 'KLOP LOCATIE TOEVOEGEN' : 'ADD LOCATION';
    const emptyText = isWash ? 'Nog geen klop locaties toegevoegd.' : 'Nog geen actiepunten toegevoegd.';
    const totalPages = Math.max(1, Math.ceil(steps.length / state.stepsPerPage));
    state.stepPage = Math.max(0, Math.min(state.stepPage, totalPages - 1));
    const start = state.stepPage * state.stepsPerPage;
    const visible = steps.slice(start, start + state.stepsPerPage);
    return `
        <div class="card">
            <div class="card-title">
                <div><h3>${title}</h3></div>
                <button class="primary" data-action="add-step">${addLabel}</button>
            </div>
            ${visible.map((s, idx) => stepCard(s, start + idx)).join('') || `<p class="muted">${emptyText}</p>`}
            <div class="step-pager">
                <button class="small" data-action="step-prev" ${state.stepPage <= 0 ? 'disabled' : ''}>Vorige pagina</button>
                <span class="muted">Pagina ${state.stepPage + 1} / ${totalPages} • ${steps.length} locaties</span>
                <button class="small" data-action="step-next" ${state.stepPage >= totalPages - 1 ? 'disabled' : ''}>Volgende pagina</button>
            </div>
        </div>
    `;
}

function stepCard(s, i) {
    s.coords = s.coords || { x: 0, y: 0, z: 0, h: 0 };
    s.animation = s.animation || { preset: 'none' };
    s.door = s.door || {};
    const collapsed = state.collapsedSteps && state.collapsedSteps[i] === true;
    const summary = `${actionLabel(s.action_type || 'collect')} • ${Math.round((s.coords.x || 0) * 100) / 100}, ${Math.round((s.coords.y || 0) * 100) / 100}, ${Math.round((s.coords.z || 0) * 100) / 100}`;

    if (collapsed) {
        return `
            <div class="card step-card collapsed">
                <div class="card-title">
                    <div>
                        <h3>#${i + 1} ${esc(s.label || 'Actiepunt')}</h3>
                        <p class="muted">${esc(summary)}</p>
                    </div>
                    <div class="row">
                        <button class="small" data-toggle-step="${i}">Openen</button>
                        <button class="danger small" data-remove-step="${i}">Verwijderen</button>
                    </div>
                </div>
            </div>
        `;
    }

    return `
        <div class="card step-card">
            <div class="card-title">
                <div>
                    <h3>#${i + 1} ${esc(s.label || 'Actiepunt')}</h3>
                    <p class="muted">${esc(summary)}</p>
                </div>
                <div class="row">
                    <button class="small" data-toggle-step="${i}">Inklappen</button>
                    <button class="small" data-step-current="${i}">Gebruik huidige locatie</button>
                    <button class="small" data-step-preview="${i}">Preview animatie</button>
                    <button class="danger small" data-remove-step="${i}">Verwijderen</button>
                </div>
            </div>
            <div class="grid three">
                <div class="field"><label>Label</label><input data-step="${i}" data-prop="label" value="${esc(s.label || '')}"></div>
                <div class="field"><label>Actietype</label><select data-step="${i}" data-prop="action_type">${actionOptions(s.action_type || 'collect')}</select></div>
                <div class="field"><label>Duur ms</label><input data-step="${i}" data-prop="duration" type="number" value="${s.duration || ''}" placeholder="Standaard activiteit"></div>
                <div class="field"><label>X</label><input data-step-coord="${i}" data-prop="x" type="number" step="0.0001" value="${s.coords.x || 0}"></div>
                <div class="field"><label>Y</label><input data-step-coord="${i}" data-prop="y" type="number" step="0.0001" value="${s.coords.y || 0}"></div>
                <div class="field"><label>Z</label><input data-step-coord="${i}" data-prop="z" type="number" step="0.0001" value="${s.coords.z || 0}"></div>
                <div class="field"><label>Heading</label><input data-step-coord="${i}" data-prop="h" type="number" step="0.0001" value="${s.coords.h || 0}"></div>
                <div class="field"><label>Minigame</label><select data-step="${i}" data-prop="minigame"><option value="" ${s.minigame == null ? 'selected' : ''}>Activiteit standaard</option><option value="true" ${s.minigame === true ? 'selected' : ''}>Aan</option><option value="false" ${s.minigame === false ? 'selected' : ''}>Uit</option></select></div>
                <div class="field"><label>Moeilijkheid</label><select data-step="${i}" data-prop="minigame_difficulty">${difficultyOptions(s.minigame_difficulty || '')}</select></div>
                <div class="field"><label>Animatie preset</label><select data-step-animation="${i}" data-prop="preset">${presetOptions(s.animation.preset || 'none')}</select></div>
                <div class="field"><label>Required item stap</label><input data-step="${i}" data-prop="required_item" value="${esc(s.required_item || '')}" placeholder="lockpick"></div>
                <div class="field"><label>Aantal</label><input data-step="${i}" data-prop="required_amount" type="number" value="${s.required_amount || 1}"></div>
            </div>
            <div class="hr"></div>
            <div class="grid three">
                <div class="field"><label>Reward naam</label><input data-step="${i}" data-prop="reward" value="${esc(s.reward || '')}" placeholder="coke_bag"></div>
                <div class="field"><label>Reward type</label><select data-step="${i}" data-prop="reward_type"><option value="item" ${s.reward_type !== 'account' ? 'selected' : ''}>Item</option><option value="account" ${s.reward_type === 'account' ? 'selected' : ''}>Geld/account</option></select></div>
                <div class="field"><label>Reward min</label><input data-step="${i}" data-prop="reward_min" type="number" value="${s.reward_min || s.reward_amount || 1}"></div>
                <div class="field"><label>Reward max</label><input data-step="${i}" data-prop="reward_max" type="number" value="${s.reward_max || s.reward_amount || 1}"></div>
                <div class="field"><label>Reward kans %</label><input data-step="${i}" data-prop="reward_chance" type="number" value="${s.reward_chance ?? 100}"></div>
                <label class="switch-row"><span>Required verwijderen</span><input data-step="${i}" data-prop="remove_required" type="checkbox" ${s.remove_required ? 'checked' : ''}></label>
            </div>
            <div class="hr"></div>
            <div class="card-title"><h3>Custom doorlock alsof ox_doorlock</h3><button class="small" data-capture-door="${i}">Pak dichtstbijzijnde deur</button></div>
            <div class="grid three">
                <div class="field"><label>ox_doorlock ID</label><input data-door="${i}" data-prop="id" value="${esc(s.door.id || '')}"></div>
                <div class="field"><label>Model/hash</label><input data-door="${i}" data-prop="model" value="${esc(s.door.model || '')}"></div>
                <div class="field"><label>Na actie</label><select data-door="${i}" data-prop="afterAction"><option value="none" ${s.door.afterAction === 'none' ? 'selected' : ''}>Niks</option><option value="unlock" ${s.door.afterAction === 'unlock' ? 'selected' : ''}>Unlock</option><option value="lock" ${s.door.afterAction === 'lock' ? 'selected' : ''}>Lock</option><option value="toggle" ${s.door.afterAction === 'toggle' ? 'selected' : ''}>Toggle</option></select></div>
                <label class="switch-row"><span>Standaard op slot</span><input data-door="${i}" data-prop="defaultLocked" type="checkbox" ${s.door.defaultLocked ? 'checked' : ''}></label>
                <div class="field"><label>Relock delay ms</label><input data-door="${i}" data-prop="relockDelay" type="number" value="${s.door.relockDelay || 0}"></div>
                <div class="field"><label>Deur coords</label><input readonly value="${s.door.coords ? `${s.door.coords.x}, ${s.door.coords.y}, ${s.door.coords.z}` : 'Niet ingesteld'}"></div>
            </div>
        </div>
    `;
}


function drugTypes() {
    return state.config.drugTypes || [];
}

function currentDrugType(a) {
    const types = drugTypes();
    const d = (a && a.settings && a.settings.drugs) || {};
    return types.find(x => x.value === d.drugType) || types[0] || null;
}

function drugTypeOptions(current) {
    const types = drugTypes();
    if (!types.length) return `<option value="coke">Coke</option>`;
    return types.map(x => `<option value="${esc(x.value)}" ${x.value === current ? 'selected' : ''}>${esc(x.label)}</option>`).join('');
}

function drugIconHtml(drug) {
    if (!drug || !drug.icon) return '';
    return `<img class="drug-icon" src="${esc(drug.icon)}" alt="${esc(drug.label || 'Drug')}">`;
}

function applyDrugTypeDefaults(a) {
    if (!a) return;
    a.settings = a.settings || {};
    a.settings.drugs = a.settings.drugs || {};
    const d = a.settings.drugs;
    const drug = currentDrugType(a);
    if (!drug) return;
    const category = normalizeCategory(a.category);
    if (category === 'drugs_plukken') {
        d.pickRewardItem = drug.pickItem || d.pickRewardItem || 'coke_leaf';
        d.animation = d.animation || 'drug_pick';
    } else if (category === 'drugs_verwerken') {
        d.mode = d.mode === 'package' ? 'package' : 'process';
        if (d.mode === 'package') {
            d.inputItem = drug.packageInput || drug.processOutput || d.inputItem || 'coke_powder';
            d.outputItem = drug.packageOutput || drug.sellItem || d.outputItem || 'coke_bag';
            d.animation = d.animation || 'drug_package';
        } else {
            d.inputItem = drug.processInput || drug.pickItem || d.inputItem || 'coke_leaf';
            d.outputItem = drug.processOutput || d.outputItem || 'coke_powder';
            d.animation = d.animation || 'drug_process';
        }
    }
}

function renderDrugs(a) {
    a.settings.drugs = a.settings.drugs || {};
    const d = a.settings.drugs;
    const category = normalizeCategory(a.category);
    const isPick = category === 'drugs_plukken';
    const isPackage = !isPick && d.mode === 'package';
    const title = isPick ? 'Drugs pluk instellingen' : 'Verwerk / verpak instellingen';
    const actionName = isPick ? 'Plukken' : (isPackage ? 'Verpakken' : 'Verwerken');
    const defaultAnim = isPick ? 'drug_pick' : (isPackage ? 'drug_package' : 'drug_process');
    if (!d.drugType) d.drugType = 'coke';
    if (!isPick) d.mode = isPackage ? 'package' : 'process';
    if (!d.animation) d.animation = defaultAnim;
    const drug = currentDrugType(a);

    if (isPick) {
        return `
            <div class="card process-hero drug-hero">
                <div class="drug-hero-left">
                    ${drugIconHtml(drug)}
                    <div>
                        <h3>${title}</h3>
                        <div class="field compact"><label>Drug soort</label><select data-drugs="drugType">${drugTypeOptions(d.drugType)}</select></div>
                    </div>
                </div>
                <button class="primary" data-action="apply-drugs-settings">Toepassen op actiepunten</button>
            </div>
            <div class="process-flow">
                <div class="flow-box"><strong>Locatie</strong><span>Speler drukt E</span></div>
                <div class="flow-arrow">→</div>
                <div class="flow-box"><strong>${actionName}</strong><span>Animatie + timer</span></div>
                <div class="flow-arrow">→</div>
                <div class="flow-box"><strong>Reward</strong><span>${esc(d.pickRewardItem || 'item')}</span></div>
            </div>
            <div class="card">
                <div class="card-title"><h3>Pluk reward</h3></div>
                <div class="grid three">
                    <div class="field"><label>Reward item</label><input data-drugs="pickRewardItem" value="${esc(d.pickRewardItem || 'coke_leaf')}"></div>
                    <div class="field"><label>Min aantal</label><input data-drugs="pickRewardMin" type="number" value="${d.pickRewardMin || 1}"></div>
                    <div class="field"><label>Max aantal</label><input data-drugs="pickRewardMax" type="number" value="${d.pickRewardMax || 3}"></div>
                    <div class="field"><label>Required item optioneel</label><input data-drugs="requiredItem" value="${esc(d.requiredItem || '')}" placeholder="bijv. schaar"></div>
                    <div class="field"><label>Required aantal</label><input data-drugs="requiredAmount" type="number" value="${d.requiredAmount || 1}"></div>
                    <label class="switch-row"><span>Required verwijderen</span><input data-drugs="removeRequired" type="checkbox" ${d.removeRequired === true ? 'checked' : ''}></label>
                </div>
            </div>
            <div class="card">
                <div class="card-title"><h3>Uitvoering</h3></div>
                <div class="grid three">
                    <div class="field"><label>Duur ms</label><input data-drugs="duration" type="number" value="${d.duration || 7500}"></div>
                    <label class="switch-row"><span>Minigame</span><input data-drugs="minigame" type="checkbox" ${d.minigame === true ? 'checked' : ''}></label>
                    <div class="field"><label>Moeilijkheid</label><select data-drugs="difficulty">${difficultyOptions(d.difficulty || 'normal')}</select></div>
                    <div class="field"><label>Animatie</label><select data-drugs="animation">${presetOptions(d.animation || 'drug_pick')}</select></div>
                </div>
            </div>
        `;
    }

    return `
        <div class="card process-hero drug-hero">
            <div class="drug-hero-left">
                ${drugIconHtml(drug)}
                <div>
                    <h3>${title}</h3>
                    <div class="grid two compact-grid">
                        <div class="field compact"><label>Drug soort</label><select data-drugs="drugType">${drugTypeOptions(d.drugType)}</select></div>
                        <div class="field compact"><label>Actie</label><select data-drugs="mode"><option value="process" ${!isPackage ? 'selected' : ''}>Verwerken</option><option value="package" ${isPackage ? 'selected' : ''}>Verpakken</option></select></div>
                    </div>
                </div>
            </div>
            <button class="primary" data-action="apply-drugs-settings">Toepassen op actiepunten</button>
        </div>
        <div class="process-flow">
            <div class="flow-box"><strong>Input</strong><span>${esc(d.inputItem || 'input_item')}</span></div>
            <div class="flow-arrow">→</div>
            <div class="flow-box"><strong>${actionName}</strong><span>Timer / minigame</span></div>
            <div class="flow-arrow">→</div>
            <div class="flow-box"><strong>Output</strong><span>${esc(d.outputItem || 'output_item')}</span></div>
        </div>
        <div class="card">
            <div class="card-title"><h3>Input & output</h3></div>
            <div class="grid three">
                <div class="field"><label>Input item</label><input data-drugs="inputItem" value="${esc(d.inputItem || 'coke_leaf')}"></div>
                <div class="field"><label>Input aantal</label><input data-drugs="inputAmount" type="number" value="${d.inputAmount || 1}"></div>
                <div class="field"><label>Output item</label><input data-drugs="outputItem" value="${esc(d.outputItem || (isPackage ? 'coke_bag' : 'coke_powder'))}"></div>
                <div class="field"><label>Output min</label><input data-drugs="outputMin" type="number" value="${d.outputMin || 1}"></div>
                <div class="field"><label>Output max</label><input data-drugs="outputMax" type="number" value="${d.outputMax || 1}"></div>
                <label class="switch-row"><span>Input verwijderen</span><input data-drugs="removeRequired" type="checkbox" ${d.removeRequired !== false ? 'checked' : ''}></label>
            </div>
        </div>
        <div class="card">
            <div class="card-title"><h3>Uitvoering</h3></div>
            <div class="grid three">
                <div class="field"><label>Duur ms</label><input data-drugs="duration" type="number" value="${d.duration || 7500}"></div>
                <label class="switch-row"><span>Minigame</span><input data-drugs="minigame" type="checkbox" ${d.minigame === true ? 'checked' : ''}></label>
                <div class="field"><label>Moeilijkheid</label><select data-drugs="difficulty">${difficultyOptions(d.difficulty || 'normal')}</select></div>
                <div class="field"><label>Animatie</label><select data-drugs="animation">${presetOptions(d.animation || defaultAnim)}</select></div>
            </div>
        </div>
        <div class="card">
            <div class="card-title"><h3>Extra opties</h3></div>
            <p class="muted">Gebruik de tab Visuele bouwer voor extra blokken.</p>
        </div>
    `;
}

function applyDrugsSettingsToSteps() {
    const a = selectedOrDefault();
    applyDrugTypeDefaults(a);
    const d = a.settings.drugs || {};
    const category = normalizeCategory(a.category);
    const isPick = category === 'drugs_plukken';
    const isPackage = !isPick && d.mode === 'package';
    const actionType = isPick ? 'collect' : (isPackage ? 'package' : 'process');
    const anim = d.animation || (isPick ? 'drug_pick' : (isPackage ? 'drug_package' : 'drug_process'));

    (a.action_points || []).forEach((step, idx) => {
        step.action_type = actionType;
        step.duration = Number(d.duration || step.duration || a.duration || 7500);
        step.minigame = d.minigame === true;
        step.minigame_difficulty = d.difficulty || a.minigame_difficulty || 'normal';
        step.animation = { preset: anim };
        if (isPick) {
            step.label = step.label || `Pluk locatie ${idx + 1}`;
            step.required_item = d.requiredItem || '';
            step.required_amount = Number(d.requiredAmount || 1);
            step.remove_required = d.removeRequired === true;
            step.reward = d.pickRewardItem || 'coke_leaf';
            step.reward_min = Number(d.pickRewardMin || 1);
            step.reward_max = Number(d.pickRewardMax || d.pickRewardMin || 1);
            step.reward_type = 'item';
            step.reward_chance = 100;
        } else {
            step.label = step.label || `${isPackage ? 'Verpak' : 'Verwerk'} locatie ${idx + 1}`;
            step.required_item = d.inputItem || 'coke_leaf';
            step.required_amount = Number(d.inputAmount || 1);
            step.remove_required = d.removeRequired !== false;
            step.reward = d.outputItem || (isPackage ? 'coke_bag' : 'coke_powder');
            step.reward_min = Number(d.outputMin || 1);
            step.reward_max = Number(d.outputMax || d.outputMin || 1);
            step.reward_type = 'item';
            step.reward_chance = 100;
        }
    });
    renderPanel();
}

function renderPolitie(a) {
    const p = a.settings.police || {};
    return `
        <div class="card">
            <div class="card-title"><h3>Politie melding systeem</h3></div>
            <div class="grid three">
                ${switchHtml('alert_police', 'Politie alert aan/uit', a.alert_police)}
                ${switchHtml('police_blip', 'Politie blip aan/uit', a.police_blip)}
                <div class="field"><label>Benodigde politie</label><input data-field="min_police" type="number" value="${a.min_police || 0}"></div>
                <div class="field"><label>Benodigde politie rang</label><input data-field="min_police_grade" type="number" value="${a.min_police_grade || 0}"></div>
                <div class="field"><label>Alert bij</label><select data-setting="alertOn"><option value="start" ${a.settings.alertOn !== 'step' ? 'selected' : ''}>Start</option><option value="step" ${a.settings.alertOn === 'step' ? 'selected' : ''}>Specifieke stap</option></select></div>
                <div class="field"><label>Alert stapnummer</label><input data-setting="alertStep" type="number" value="${a.settings.alertStep || 1}"></div>
                <div class="field"><label>Alert kans %</label><input data-police="chance" type="number" value="${p.chance ?? 100}"></div>
                <div class="field"><label>Blip duur seconden</label><input data-field="police_blip_time" type="number" value="${a.police_blip_time || 60}"></div>
                <div class="field"><label>Blip radius</label><input data-police="radius" type="number" value="${p.radius || 75}"></div>
                <div class="field"><label>Blip sprite</label><input data-police="sprite" type="number" value="${p.sprite || 161}"></div>
                <div class="field"><label>Blip kleur</label><input data-police="color" type="number" value="${p.color || 1}"></div>
                <div class="field"><label>Blip schaal</label><input data-police="scale" type="number" step="0.1" value="${p.scale || 1.2}"></div>
            </div>
            <div class="field" style="margin-top:16px"><label>Melding tekst</label><textarea data-police="text">${esc(p.text || 'Verdachte illegale activiteit gemeld in de buurt.')}</textarea></div>
        </div>
    `;
}

function renderWitwas(a) {
    const w = a.settings.wash || {};
    const r = w.route || {};
    const jobs = w.jobs || [];
    return `
        <div class="card">
            <div class="card-title"><h3>Witwas route systeem</h3></div>
            <div class="grid three">
                <label class="switch-row"><span>Route witwas aan/uit</span><input data-wash-route="enabled" type="checkbox" ${r.enabled !== false ? 'checked' : ''}></label>
                <div class="field"><label>Input account</label><input data-wash="input" value="${esc(w.input || 'black_money')}"></div>
                <div class="field"><label>Output account</label><input data-wash="output" value="${esc(w.output || 'money')}"></div>
                <div class="field"><label>Standaard percentage</label><input data-wash="percentage" type="number" value="${w.percentage ?? 50}"></div>
                <div class="field"><label>Max percentage zonder job</label><input data-wash="maxPercentage" type="number" value="${w.maxPercentage ?? 50}"></div>
                <div class="field"><label>Fee %</label><input data-wash="fee" type="number" value="${w.fee || 0}"></div>
                <div class="field"><label>Minimaal bedrag</label><input data-wash="minAmount" type="number" value="${w.minAmount || 10000}"></div>
                <div class="field"><label>Maximaal bedrag</label><input data-wash="maxAmount" type="number" value="${w.maxAmount || 100000}"></div>
            </div>
        </div>
        <div class="card">
            <div class="card-title"><h3>NPC & voertuig</h3></div>
            <div class="grid three">
                <div class="field"><label>NPC model</label><input data-wash-route="pedModel" value="${esc(r.pedModel || 's_m_m_highsec_01')}"></div>
                <div class="field"><label>NPC scenario</label><input data-wash-route="pedScenario" value="${esc(r.pedScenario || 'WORLD_HUMAN_CLIPBOARD')}"></div>
                <div class="field"><label>Busje model</label><input data-wash-route="vehicleModel" value="${esc(r.vehicleModel || 'speedo')}"></div>
                <label class="switch-row"><span>Eigen voertuig upgrade aan</span><input data-wash-route="ownVehicleUpgradeEnabled" type="checkbox" ${r.ownVehicleUpgradeEnabled !== false ? 'checked' : ''}></label>
                <div class="field"><label>Upgrade prijs eenmalig</label><input data-wash-route="ownVehicleUpgradePrice" type="number" value="${r.ownVehicleUpgradePrice || 200000}"></div>
                <div class="field"><label>Upgrade account</label><input data-wash-route="ownVehicleUpgradeAccount" value="${esc(r.ownVehicleUpgradeAccount || 'bank')}"></div>
            </div>
        </div>
        <div class="card">
            <div class="card-title"><h3>Route locaties & wachttijd</h3></div>
            <div class="grid three">
                <div class="field"><label>Min random locaties</label><input data-wash-route="minStops" type="number" value="${r.minStops || 2}"></div>
                <div class="field"><label>Max random locaties</label><input data-wash-route="maxStops" type="number" value="${r.maxStops || 4}"></div>
                <label class="switch-row"><span>Random wachttijd gebruiken</span><input data-wash-route="randomDuration" type="checkbox" ${r.randomDuration !== false ? 'checked' : ''}></label>
                <div class="field"><label>Vaste wachttijd ms</label><input data-wash-route="duration" type="number" value="${r.duration || 10000}"></div>
                <div class="field"><label>Random min ms</label><input data-wash-route="randomDurationMin" type="number" value="${r.randomDurationMin || 8000}"></div>
                <div class="field"><label>Random max ms</label><input data-wash-route="randomDurationMax" type="number" value="${r.randomDurationMax || 18000}"></div>
            </div>
        </div>
        <div class="card">
            <div class="card-title"><h3>Job percentages</h3><button class="small" data-action="add-wash-job">+ Job toevoegen</button></div>
            <div class="list-stack">
                ${jobs.map((j, i) => `
                    <div class="item-row">
                        <div class="field"><label>Job naam</label><input data-wash-job="${i}" data-prop="job" value="${esc(j.job || '')}" placeholder="ballas"></div>
                        <div class="field"><label>Percentage</label><input data-wash-job="${i}" data-prop="percentage" type="number" value="${j.percentage || 60}"></div>
                        <div></div><div></div><div></div>
                        <button class="danger small" data-remove-wash-job="${i}">X</button>
                    </div>
                `).join('') || '<p class="muted">Geen job percentages ingesteld.</p>'}
            </div>
        </div>
    `;
}


function builderField(block, i) {
    const input = (prop, label, type = 'text', value = '') => `<div class="field"><label>${label}</label><input data-builder-block="${i}" data-prop="${prop}" type="${type}" value="${esc(value)}"></div>`;
    const checkbox = (prop, label, checked) => `<label class="switch-row"><span>${label}</span><input data-builder-block="${i}" data-prop="${prop}" type="checkbox" ${checked ? 'checked' : ''}></label>`;

    if (block.type === 'required_item') {
        return `${input('name', 'Item naam', 'text', block.name || '')}${input('amount', 'Aantal', 'number', block.amount || 1)}${checkbox('remove', 'Verwijderen na succes', block.remove === true)}`;
    }
    if (block.type === 'remove_item') {
        return `${input('name', 'Item naam', 'text', block.name || '')}${input('amount', 'Aantal', 'number', block.amount || 1)}<div class="builder-note">Dit item wordt server-side verwijderd.</div>`;
    }
    if (block.type === 'reward_item') {
        return `${input('name', 'Reward item', 'text', block.name || '')}${input('min', 'Min aantal', 'number', block.min || 1)}${input('max', 'Max aantal', 'number', block.max || 1)}${input('chance', 'Kans %', 'number', block.chance ?? 100)}${checkbox('guaranteed', 'Altijd geven', block.guaranteed !== false)}`;
    }
    if (block.type === 'reward_money') {
        return `<div class="field"><label>Account</label><select data-builder-block="${i}" data-prop="account"><option value="money" ${block.account === 'money' ? 'selected' : ''}>money</option><option value="black_money" ${block.account === 'black_money' ? 'selected' : ''}>black_money</option><option value="bank" ${block.account === 'bank' ? 'selected' : ''}>bank</option></select></div>${input('min', 'Min bedrag', 'number', block.min || 100)}${input('max', 'Max bedrag', 'number', block.max || 250)}${input('chance', 'Kans %', 'number', block.chance ?? 100)}${checkbox('guaranteed', 'Altijd geven', block.guaranteed !== false)}`;
    }
    if (block.type === 'progress') {
        return `${input('label', 'Progress tekst', 'text', block.label || 'Verwerken')}${input('duration', 'Duur ms', 'number', block.duration || 7500)}`;
    }
    if (block.type === 'minigame') {
        return `${checkbox('enabled', 'Minigame aan', block.enabled === true)}<div class="field"><label>Moeilijkheid</label><select data-builder-block="${i}" data-prop="difficulty">${difficultyOptions(block.difficulty || 'normal')}</select></div>`;
    }
    if (block.type === 'animation') {
        return `<div class="field"><label>Preset</label><select data-builder-block="${i}" data-prop="preset">${presetOptions(block.preset || 'drug_process')}</select></div>`;
    }
    if (block.type === 'police') {
        return `${checkbox('enabled', 'Politie melding bij deze actie', block.enabled === true)}${input('chance', 'Kans %', 'number', block.chance ?? 25)}`;
    }
    return '';
}

function builderBlockHtml(block, i) {
    return `
        <div class="builder-block" draggable="true" data-builder-index="${i}">
            <div class="builder-block-head">
                <strong>${esc(builderBlockTitle(block))}</strong>
                <div class="row">
                    <button class="small" data-builder-up="${i}">↑</button>
                    <button class="small" data-builder-down="${i}">↓</button>
                    <button class="danger small" data-builder-remove="${i}">X</button>
                </div>
            </div>
            <div class="builder-fields">
                ${builderField(block, i)}
            </div>
        </div>
    `;
}

function renderBouwer(a) {
    const builder = getBuilder(a);
    const templates = builderTemplates();
    return `
        <div class="card builder-card">
            <div class="card-title">
                <div>
                    <h3>Visuele verwerk bouwer</h3>
                    <p class="muted">Sleep blokken naar het werkveld of klik op een blok.</p>
                </div>
                <label class="switch-row compact"><span>Gebruiken</span><input data-builder-root="enabled" type="checkbox" ${builder.enabled ? 'checked' : ''}></label>
            </div>
            <div class="builder-layout">
                <div class="builder-palette">
                    <h4>Blokken</h4>
                    ${templates.map(t => `<button class="builder-palette-item" draggable="true" data-builder-template="${t.type}"><span>${t.icon}</span>${esc(t.label)}</button>`).join('')}
                </div>
                <div class="builder-canvas" data-builder-drop="true">
                    <div class="builder-canvas-title">
                        <h4>Werkveld</h4>
                        <span class="muted">${builder.blocks.length} blokken</span>
                    </div>
                    ${builder.blocks.map((block, i) => builderBlockHtml(block, i)).join('') || '<div class="builder-empty">Sleep hier blokken om je verwerk systeem te maken.</div>'}
                </div>
            </div>
        </div>
        <div class="card">
            <div class="card-title"><h3>Hoe wordt dit gebruikt?</h3></div>
            <div class="grid three">
                <div class="builder-info"><strong>Benodigd</strong><span>Wordt server-side gecontroleerd.</span></div>
                <div class="builder-info"><strong>Verwijderen</strong><span>Wordt pas verwijderd na een geslaagde actie.</span></div>
                <div class="builder-info"><strong>Reward</strong><span>Wordt nooit client-side gegeven.</span></div>
            </div>
        </div>
    `;
}

function renderInstellingen(a) {
    return `
        <div class="card">
            <div class="card-title"><h3>Creator instellingen</h3></div>
            <div class="grid three">
                <label class="switch-row"><span>Waypoint naar volgende stap</span><input data-setting="waypoint" type="checkbox" ${a.settings.waypoint !== false ? 'checked' : ''}></label>
                <label class="switch-row"><span>Eén speler tegelijk</span><input data-setting="onePlayerOnly" type="checkbox" ${a.settings.onePlayerOnly ? 'checked' : ''}></label>
                <div class="field"><label>UI thema</label><button data-action="toggle-theme">Wissel donker/licht</button></div>
            </div>
            <div class="hr"></div>
            <p class="muted">Debug, admin groepen, ACE, politie jobs, security limits, markers, blips, animatie presets en quick-add items pas je aan in <span class="code">shared/config.lua</span>.</p>
        </div>
    `;
}

function renderPanel() {
    ensureAllowedTab();
    if (!state.selected) {
        panel.className = 'panel empty';
        panel.innerHTML = `
            <div class="empty-state">
                <div class="logo big">HBH</div>
                <h3>Selecteer of maak een activiteit</h3>
                <p>Gebruik de creator om witwas, drugs, craft, transport, lab, dropoff en custom illegale activiteiten te bouwen.</p>
            </div>`;
        editorTitle.textContent = 'Geen activiteit geselecteerd';
        editorSub.textContent = 'Maak of selecteer een activiteit.';
        return;
    }

    const a = selectedOrDefault();
    panel.className = 'panel';
    editorTitle.textContent = a.name || 'Nieuwe activiteit';
    editorSub.textContent = `${categoryLabel(a.category)} • ${a.enabled ? 'Aan' : 'Uit'} • ${(a.action_points || []).length} actiepunten`;

    const map = {
        basis: renderBasis,
        stappen: renderStappen,
        items: renderItems,
        drugs: renderDrugs,
        bouwer: renderBouwer,
        politie: renderPolitie,
        witwas: renderWitwas,
        instellingen: renderInstellingen
    };
    panel.innerHTML = (map[state.tab] || renderBasis)(a);
}

function renderTabs() {
    ensureAllowedTab();
    const a = state.selected ? selectedOrDefault() : null;
    const allowed = visibleTabsFor(a);
    document.querySelectorAll('.tab').forEach(btn => {
        const tab = btn.dataset.tab;
        btn.classList.toggle('hidden', !allowed.includes(tab));
        btn.classList.toggle('active', tab === state.tab);
        if (tab === 'stappen') {
            btn.textContent = a && a.category === 'witwassen' ? 'Klop locaties' : 'Actiepunten';
        }
        if (tab === 'drugs') {
            if (a && normalizeCategory(a.category) === 'drugs_plukken') btn.textContent = 'Drugs pluk';
            else btn.textContent = 'Verwerken / verpakken';
        }
        if (tab === 'bouwer') {
            btn.textContent = 'Visuele bouwer';
        }
    });
}

function render() {
    renderList();
    renderTabs();
    renderPanel();
}

function setTheme(theme) {
    document.body.classList.toggle('light', theme === 'light');
    localStorage.setItem('hbh_illegal_theme', theme);
}

function toggleTheme() {
    setTheme(document.body.classList.contains('light') ? 'dark' : 'light');
}

async function refresh() {
    const data = await post('getData');
    if (data.ok) {
        state.activities = data.activities || [];
        state.config = data.config || state.config || {};
        if (state.selected?.id) {
            const fresh = state.activities.find(a => Number(a.id) === Number(state.selected.id));
            if (fresh) state.selected = clone(fresh);
        }
        render();
    }
}

async function save() {
    if (!state.selected) return;
    const res = await post('saveActivity', { activity: state.selected });
    if (!res.ok) {
        await post('adminNotify', { message: res.message || 'Opslaan mislukt.', type: 'error' });
        return;
    }
    if (res.activity) state.selected = clone(res.activity);
    await refresh();
}

async function removeSelected() {
    if (!state.selected?.id) return;
    const ok = await nuiConfirm(`Weet je zeker dat je ${state.selected.name} wilt verwijderen?`, 'Activiteit verwijderen');
    if (!ok) return;
    const res = await post('deleteActivity', { id: state.selected.id });
    if (!res.ok) {
        await post('adminNotify', { message: res.message || 'Verwijderen mislukt.', type: 'error' });
        return;
    }
    state.selected = null;
    await refresh();
}

async function useCurrentStart() {
    const res = await post('getCurrentCoords');
    if (res.ok) {
        selectedOrDefault().coords = res.coords;
        renderPanel();
    }
}

async function useCurrentVehicleSpawn() {
    const res = await post('getCurrentCoords');
    if (res.ok) {
        const a = selectedOrDefault();
        a.settings.wash = a.settings.wash || {};
        a.settings.wash.route = a.settings.wash.route || {};
        a.settings.wash.route.vehicleSpawn = res.coords;
        renderPanel();
    }
}

async function addStep() {
    const a = selectedOrDefault();
    applyDrugTypeDefaults(a);
    const d = a.settings.drugs || {};
    const res = await post('getCurrentCoords');
    let defaultLabel = `Stap ${(a.action_points || []).length + 1}`;
    let actionType = 'collect';
    let anim = 'none';
    let reward = '';
    let rewardMin = 1;
    let rewardMax = 1;
    let required = '';
    let requiredAmount = 1;
    let removeRequired = false;

    if (a.category === 'witwassen') {
        defaultLabel = `Klop locatie ${(a.action_points || []).length + 1}`;
        actionType = 'wash_route_stop';
        anim = 'knock';
    } else if (normalizeCategory(a.category) === 'drugs_plukken') {
        defaultLabel = `Pluk locatie ${(a.action_points || []).length + 1}`;
        actionType = 'collect';
        anim = d.animation || 'drug_pick';
        reward = d.pickRewardItem || 'coke_leaf';
        rewardMin = Number(d.pickRewardMin || 1);
        rewardMax = Number(d.pickRewardMax || d.pickRewardMin || 3);
        required = d.requiredItem || '';
        requiredAmount = Number(d.requiredAmount || 1);
        removeRequired = d.removeRequired === true;
    } else if (normalizeCategory(a.category) === 'drugs_verwerken') {
        const pack = d.mode === 'package';
        defaultLabel = `${pack ? 'Verpak' : 'Verwerk'} locatie ${(a.action_points || []).length + 1}`;
        actionType = pack ? 'package' : 'process';
        anim = d.animation || (pack ? 'drug_package' : 'drug_process');
        reward = d.outputItem || (pack ? 'coke_bag' : 'coke_powder');
        rewardMin = Number(d.outputMin || 1);
        rewardMax = Number(d.outputMax || d.outputMin || 1);
        required = d.inputItem || 'coke_leaf';
        requiredAmount = Number(d.inputAmount || 1);
        removeRequired = d.removeRequired !== false;
    }

    const label = await nuiPrompt('Naam van deze locatie:', defaultLabel, 'Locatie toevoegen');
    if (label === null) return;
    const newIndex = (a.action_points || []).length;
    a.action_points.push({
        label: label || defaultLabel,
        coords: res.ok ? res.coords : { x: 0, y: 0, z: 0, h: 0 },
        action_type: actionType,
        duration: Number((a.settings.drugs && a.settings.drugs.duration) || a.duration || 7500),
        progressbar: null,
        minigame: normalizeCategory(a.category).startsWith('drugs_') ? (d.minigame === true) : null,
        minigame_difficulty: (d.difficulty || a.minigame_difficulty || 'normal'),
        animation: { preset: anim },
        required_item: required,
        required_amount: requiredAmount,
        remove_required: removeRequired,
        reward: reward,
        reward_min: rewardMin,
        reward_max: rewardMax,
        reward_chance: 100,
        reward_type: 'item',
        door: { afterAction: 'none', defaultLocked: false, relockDelay: 0 }
    });
    state.collapsedSteps[newIndex] = false;
    renderPanel();
}

async function setStepCurrent(i) {
    const res = await post('getCurrentCoords');
    if (res.ok) {
        selectedOrDefault().action_points[i].coords = res.coords;
        renderPanel();
    }
}

async function captureDoor(i) {
    const res = await post('captureDoor');
    if (!res.ok) {
        await post('adminNotify', { message: res.message || 'Geen deur gevonden.', type: 'error' });
        return;
    }
    selectedOrDefault().action_points[i].door = res.door;
    renderPanel();
}

function addQuick(kind, type, name) {
    const a = selectedOrDefault();
    const item = { type, name: name === 'custom' ? '' : name, amount: 1, remove: false };
    const reward = { type, name: name === 'custom' ? '' : name, min: 1, max: 1, chance: 100, guaranteed: false };
    if (kind === 'required') a.required_items.push(item);
    if (kind === 'reward') a.rewards.push(reward);
    renderPanel();
}

function updateByTarget(t) {
    if (!state.selected) return;
    const a = selectedOrDefault();
    const value = t.type === 'checkbox' ? t.checked : t.value;
    let needsRender = false;

    if (t.dataset.field) {
        const key = t.dataset.field;
        if (['target_radius','max_distance','cooldown','duration','min_police','min_police_grade','police_blip_time'].includes(key)) a[key] = n(value);
        else if (['enabled','blip','marker','progressbar','minigame','alert_police','police_blip'].includes(key)) a[key] = b(value);
        else a[key] = value;
        if (key === 'category') {
            if (a.category === 'drugs_verpakken') {
                a.category = 'drugs_verwerken';
                a.settings.drugs = a.settings.drugs || {};
                a.settings.drugs.mode = 'package';
            }
            needsRender = true;
        }
    }
    if (t.dataset.coord) a.coords[t.dataset.coord] = n(value);
    if (t.dataset.animation) a.animation[t.dataset.animation] = value;
    if (t.dataset.setting) {
        const key = t.dataset.setting;
        if (t.type === 'checkbox') a.settings[key] = t.checked;
        else if (['alertStep'].includes(key)) a.settings[key] = n(value, 1);
        else a.settings[key] = value;
    }
    if (t.dataset.police) {
        a.settings.police = a.settings.police || {};
        const key = t.dataset.police;
        a.settings.police[key] = t.type === 'number' ? n(value) : value;
    }
    if (t.dataset.wash) {
        a.settings.wash = a.settings.wash || {};
        const key = t.dataset.wash;
        a.settings.wash[key] = t.type === 'number' ? n(value) : value;
    }
    if (t.dataset.drugs) {
        a.settings.drugs = a.settings.drugs || {};
        const key = t.dataset.drugs;
        if (t.type === 'checkbox') a.settings.drugs[key] = t.checked;
        else if (t.type === 'number') a.settings.drugs[key] = n(value);
        else a.settings.drugs[key] = value;
        if (key === 'drugType' || key === 'mode') {
            if (key === 'mode') {
                a.settings.drugs.animation = value === 'package' ? 'drug_package' : 'drug_process';
            }
            applyDrugTypeDefaults(a);
            renderPanel();
            return;
        }
    }
    if (t.dataset.washRoute) {
        a.settings.wash = a.settings.wash || {};
        a.settings.wash.route = a.settings.wash.route || {};
        const key = t.dataset.washRoute;
        if (t.type === 'checkbox') a.settings.wash.route[key] = t.checked;
        else if (t.type === 'number') a.settings.wash.route[key] = n(value);
        else a.settings.wash.route[key] = value;
    }
    if (t.dataset.washRouteCoord) {
        a.settings.wash = a.settings.wash || {};
        a.settings.wash.route = a.settings.wash.route || {};
        a.settings.wash.route.vehicleSpawn = a.settings.wash.route.vehicleSpawn || { x: 0, y: 0, z: 0, h: 0 };
        a.settings.wash.route.vehicleSpawn[t.dataset.washRouteCoord] = n(value);
    }
    if (t.dataset.washJob) {
        a.settings.wash = a.settings.wash || {};
        a.settings.wash.jobs = a.settings.wash.jobs || [];
        const i = Number(t.dataset.washJob), key = t.dataset.prop;
        a.settings.wash.jobs[i][key] = t.type === 'number' ? n(value) : value;
    }
    if (t.dataset.required) {
        const i = Number(t.dataset.required), key = t.dataset.prop;
        a.required_items[i][key] = t.type === 'checkbox' ? t.checked : (t.type === 'number' ? n(value) : value);
    }
    if (t.dataset.reward) {
        const i = Number(t.dataset.reward), key = t.dataset.prop;
        a.rewards[i][key] = t.type === 'number' ? n(value) : value;
    }
    if (t.dataset.step) {
        const i = Number(t.dataset.step), key = t.dataset.prop;
        const step = a.action_points[i];
        if (key === 'minigame') step[key] = value === '' ? null : value === 'true';
        else if (t.type === 'checkbox') step[key] = t.checked;
        else if (t.type === 'number') step[key] = n(value);
        else step[key] = value;
    }
    if (t.dataset.stepCoord) {
        const i = Number(t.dataset.stepCoord), key = t.dataset.prop;
        a.action_points[i].coords = a.action_points[i].coords || {};
        a.action_points[i].coords[key] = n(value);
    }
    if (t.dataset.stepAnimation) {
        const i = Number(t.dataset.stepAnimation), key = t.dataset.prop;
        a.action_points[i].animation = a.action_points[i].animation || {};
        a.action_points[i].animation[key] = value;
    }
    if (t.dataset.door) {
        const i = Number(t.dataset.door), key = t.dataset.prop;
        const door = a.action_points[i].door = a.action_points[i].door || {};
        if (t.type === 'checkbox') door[key] = t.checked;
        else if (t.type === 'number') door[key] = n(value);
        else door[key] = value;
    }
    if (t.dataset.builderRoot) {
        const builder = getBuilder(a);
        builder[t.dataset.builderRoot] = t.type === 'checkbox' ? t.checked : value;
    }
    if (t.dataset.builderBlock) {
        const builder = getBuilder(a);
        const i = Number(t.dataset.builderBlock), key = t.dataset.prop;
        if (builder.blocks[i]) {
            if (t.type === 'checkbox') builder.blocks[i][key] = t.checked;
            else if (t.type === 'number') builder.blocks[i][key] = n(value);
            else builder.blocks[i][key] = value;
        }
    }

    editorTitle.textContent = a.name || 'Nieuwe activiteit';
    if (needsRender) render();
}

modalOk?.addEventListener('click', () => {
    if (modalMode === 'prompt') closeNuiModal(modalInput.value);
    else closeNuiModal(true);
});

modalCancel?.addEventListener('click', () => closeNuiModal(modalMode === 'prompt' ? null : false));

modalEl?.addEventListener('click', e => {
    if (e.target === modalEl) closeNuiModal(modalMode === 'prompt' ? null : false);
});

modalInput?.addEventListener('keyup', e => {
    if (e.key === 'Enter') closeNuiModal(modalInput.value);
});

window.addEventListener('message', e => {
    const { action, payload } = e.data || {};
    if (action === 'open') {
        state.open = true;
        state.activities = payload.activities || [];
        state.config = payload.config || {};
        state.selected = null;
        app.classList.remove('hidden');
        render();
    }
    if (action === 'refresh' && payload?.ok) {
        state.activities = payload.activities || [];
        state.config = payload.config || state.config;
        render();
    }
    if (action === 'forceClose') {
        app.classList.add('hidden');
        state.open = false;
    }
});

document.addEventListener('DOMContentLoaded', () => {
    setTheme(localStorage.getItem('hbh_illegal_theme') || 'dark');
});

document.getElementById('newActivity').addEventListener('click', () => {
    state.selected = defaultActivity();
    state.stepPage = 0;
    state.collapsedSteps = {};
    state.tab = 'basis';
    render();
});

document.getElementById('search').addEventListener('input', e => {
    state.search = e.target.value;
    renderList();
});

document.getElementById('saveActivity').addEventListener('click', save);
document.getElementById('deleteActivity').addEventListener('click', removeSelected);
document.getElementById('close').addEventListener('click', async () => {
    app.classList.add('hidden');
    state.open = false;
    await post('close');
});
document.getElementById('themeToggle').addEventListener('click', toggleTheme);

document.querySelector('.tabs').addEventListener('click', e => {
    const btn = e.target.closest('.tab');
    if (!btn) return;
    state.tab = btn.dataset.tab;
    render();
});

listEl.addEventListener('click', e => {
    const card = e.target.closest('[data-select]');
    if (card) selectActivity(card.dataset.select);
});

panel.addEventListener('input', e => updateByTarget(e.target));
panel.addEventListener('change', e => updateByTarget(e.target));

panel.addEventListener('click', async e => {
    const t = e.target;
    if (t.dataset.action === 'use-current-start') return useCurrentStart();
    if (t.dataset.action === 'use-current-vehicle-spawn') return useCurrentVehicleSpawn();
    if (t.dataset.action === 'add-step') return addStep();
    if (t.dataset.action === 'add-required') { selectedOrDefault().required_items.push({ type: 'item', name: '', amount: 1, remove: false }); return renderPanel(); }
    if (t.dataset.action === 'add-reward') { selectedOrDefault().rewards.push({ type: 'item', name: '', min: 1, max: 1, chance: 100 }); return renderPanel(); }
    if (t.dataset.action === 'toggle-theme') return toggleTheme();
    if (t.dataset.action === 'step-prev') { state.stepPage = Math.max(0, state.stepPage - 1); return renderPanel(); }
    if (t.dataset.action === 'step-next') { state.stepPage += 1; return renderPanel(); }
    if (t.dataset.action === 'add-wash-job') { const a = selectedOrDefault(); a.settings.wash.jobs = a.settings.wash.jobs || []; a.settings.wash.jobs.push({ job: '', percentage: 60 }); return renderPanel(); }
    if (t.dataset.action === 'apply-drugs-settings') return applyDrugsSettingsToSteps();
    if (t.dataset.action === 'preview-main-animation') return post('previewAnimation', { animation: selectedOrDefault().animation, duration: 4500 });
    if (t.dataset.builderTemplate) return addBuilderBlock(t.dataset.builderTemplate);
    if (t.dataset.builderRemove != null) { const b = getBuilder(selectedOrDefault()); b.blocks.splice(Number(t.dataset.builderRemove), 1); return renderPanel(); }
    if (t.dataset.builderUp != null) { const b = getBuilder(selectedOrDefault()); const i = Number(t.dataset.builderUp); if (i > 0) { [b.blocks[i - 1], b.blocks[i]] = [b.blocks[i], b.blocks[i - 1]]; } return renderPanel(); }
    if (t.dataset.builderDown != null) { const b = getBuilder(selectedOrDefault()); const i = Number(t.dataset.builderDown); if (i < b.blocks.length - 1) { [b.blocks[i + 1], b.blocks[i]] = [b.blocks[i], b.blocks[i + 1]]; } return renderPanel(); }

    if (t.dataset.quick) return addQuick(t.dataset.quick, t.dataset.type, t.dataset.name);
    if (t.dataset.removeRequired != null) { selectedOrDefault().required_items.splice(Number(t.dataset.removeRequired), 1); return renderPanel(); }
    if (t.dataset.removeReward != null) { selectedOrDefault().rewards.splice(Number(t.dataset.removeReward), 1); return renderPanel(); }
    if (t.dataset.toggleStep != null) { const i = Number(t.dataset.toggleStep); state.collapsedSteps[i] = !state.collapsedSteps[i]; return renderPanel(); }
    if (t.dataset.removeStep != null) { selectedOrDefault().action_points.splice(Number(t.dataset.removeStep), 1); state.collapsedSteps = {}; return renderPanel(); }
    if (t.dataset.removeWashJob != null) { selectedOrDefault().settings.wash.jobs.splice(Number(t.dataset.removeWashJob), 1); return renderPanel(); }
    if (t.dataset.stepCurrent != null) return setStepCurrent(Number(t.dataset.stepCurrent));
    if (t.dataset.captureDoor != null) return captureDoor(Number(t.dataset.captureDoor));
    if (t.dataset.stepPreview != null) {
        const step = selectedOrDefault().action_points[Number(t.dataset.stepPreview)];
        return post('previewAnimation', { animation: step.animation || selectedOrDefault().animation, duration: 4500 });
    }
});


let builderDragTemplate = null;
let builderDragIndex = null;

panel.addEventListener('dragstart', e => {
    const template = e.target.closest('[data-builder-template]');
    const block = e.target.closest('[data-builder-index]');
    if (template) {
        builderDragTemplate = template.dataset.builderTemplate;
        builderDragIndex = null;
        e.dataTransfer.setData('text/plain', builderDragTemplate);
        e.dataTransfer.effectAllowed = 'copy';
    } else if (block) {
        builderDragIndex = Number(block.dataset.builderIndex);
        builderDragTemplate = null;
        e.dataTransfer.setData('text/plain', `move:${builderDragIndex}`);
        e.dataTransfer.effectAllowed = 'move';
    }
});

panel.addEventListener('dragover', e => {
    if (e.target.closest('[data-builder-drop]')) {
        e.preventDefault();
        e.dataTransfer.dropEffect = builderDragTemplate ? 'copy' : 'move';
    }
});

panel.addEventListener('drop', e => {
    const canvas = e.target.closest('[data-builder-drop]');
    if (!canvas) return;
    e.preventDefault();
    const a = selectedOrDefault();
    const builder = getBuilder(a);
    const afterBlock = e.target.closest('[data-builder-index]');
    let dropIndex = afterBlock ? Number(afterBlock.dataset.builderIndex) : builder.blocks.length;

    if (builderDragTemplate) {
        const template = builderTemplates().find(t => t.type === builderDragTemplate);
        if (template) {
            builder.blocks.splice(dropIndex, 0, { id: Date.now() + '_' + Math.floor(Math.random() * 9999), type: template.type, ...clone(template.defaults) });
            builder.enabled = true;
        }
    } else if (builderDragIndex != null && builder.blocks[builderDragIndex]) {
        const [moved] = builder.blocks.splice(builderDragIndex, 1);
        if (builderDragIndex < dropIndex) dropIndex -= 1;
        builder.blocks.splice(dropIndex, 0, moved);
    }

    builderDragTemplate = null;
    builderDragIndex = null;
    renderPanel();
});

document.addEventListener('keyup', async e => {
    if (e.key === 'Escape' && modalEl && !modalEl.classList.contains('hidden')) {
        closeNuiModal(modalMode === 'prompt' ? null : false);
        return;
    }

    if (e.key === 'Escape' && state.open) {
        app.classList.add('hidden');
        state.open = false;
        await post('close');
    }
});
