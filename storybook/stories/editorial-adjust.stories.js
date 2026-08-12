import '../styles-editorial.css';

const screen = (inner) => `<div class="screen">${inner}</div>`;

export default { title: 'Editorial/Adjust' };

// Grey is per scan, one switch — user-flows.md §7a, decision 4.
export const GreySwitch = {
  render: () => screen(`<div class="switch-row">
      <span id="grey-label">Grey</span>
      <label class="switch" for="grey" aria-labelledby="grey-label">
        <input type="checkbox" id="grey"><span class="track"></span>
      </label>
    </div>`),
};

export const ApplyToAllSwitch = {
  render: () => screen(`<div class="switch-row">
      <span id="all-label">Apply to all pages</span>
      <label class="switch" for="all" aria-labelledby="all-label">
        <input type="checkbox" id="all"><span class="track"></span>
      </label>
    </div>`),
};

export const StraightenSlider = {
  render: () => screen(`<div class="field">
      <div class="slider-head">
        <label for="straighten" style="font-size:14px">Straighten</label>
        <span class="slider-value" id="straighten-value">−1.4°</span>
      </div>
      <input class="slider" type="range" id="straighten" min="-10" max="10" step="0.1" value="-1.4"
        aria-label="Straighten, degrees" aria-valuetext="minus 1.4 degrees">
      <div class="slider-ends"><span>−10</span><span>+10</span></div>
      <button type="button" class="btn btn-ghost" style="margin-top:var(--space-2)">
        Back to the suggestion
      </button>
    </div>`),
};

export const ApplyButton = {
  render: () => screen(`<button type="button" class="btn btn-primary btn-block">Apply</button>
    <button type="button" class="btn btn-secondary btn-block">Cancel</button>`),
};

export const Applying = {
  render: () => screen(
    `<button type="button" class="btn btn-primary btn-block" disabled aria-busy="true">Applying…</button>`),
};

export const ApplyingToAllPages = {
  render: () => screen(
    `<button type="button" class="btn btn-primary btn-block" disabled aria-busy="true">Applying to 40 pages…</button>
     <p class="text-muted" style="font-size:13px;margin-top:var(--space-2)">Keep the app open.</p>`),
};
