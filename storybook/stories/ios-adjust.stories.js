import '../styles-ios.css';

export default { title: 'Variant A — iOS/Adjust' };

const wrap = (inner) => `<div class="ios">${inner}</div>`;

const greySwitch = (on) => `
  <div class="ios-group">
    <div class="ios-cell">
      <label for="grey-${on ? 'on' : 'off'}">Grey</label>
      <span class="ios-switch">
        <input type="checkbox" id="grey-${on ? 'on' : 'off'}" ${on ? 'checked' : ''}>
        <span class="ios-switch-track" aria-hidden="true"></span>
      </span>
    </div>
  </div>`;

export const GreySwitchOff = () => wrap(greySwitch(false));
export const GreySwitchOn = () => wrap(greySwitch(true));

export const StraightenSlider = () =>
  wrap(`
  <div class="ios-group">
    <div class="ios-slider-cell">
      <span class="ios-slider-head">
        <label for="straighten">Straighten</label>
        <span class="ios-value">−1.4°</span>
      </span>
      <span class="ios-slider-row">
        <span class="ios-slider-end" aria-hidden="true">−10</span>
        <input class="ios-slider" type="range" id="straighten"
               min="-10" max="10" step="0.1" value="-1.4"
               aria-label="Straighten, degrees" aria-valuetext="−1.4 degrees">
        <span class="ios-slider-end" aria-hidden="true">+10</span>
      </span>
    </div>
    <div class="ios-cell">
      <button type="button" class="ios-link">Back to the suggestion</button>
    </div>
  </div>`);

export const ApplyButton = () =>
  wrap(`
  <div class="ios-group">
    <div class="ios-cell">
      <label for="all-pages">Apply to all pages</label>
      <span class="ios-switch">
        <input type="checkbox" id="all-pages">
        <span class="ios-switch-track" aria-hidden="true"></span>
      </span>
    </div>
  </div>
  <div class="ios-stack">
    <button type="button" class="ios-btn ios-btn-primary">Apply</button>
    <button type="button" class="ios-link">Cancel</button>
  </div>`);

export const Applying = () =>
  wrap(`
  <div class="ios-stack">
    <button type="button" class="ios-btn ios-btn-primary" disabled aria-busy="true">
      <span class="ios-spinner" aria-hidden="true"></span>Applying…
    </button>
  </div>`);

export const ApplyingToAllPages = () =>
  wrap(`
  <div class="ios-stack">
    <button type="button" class="ios-btn ios-btn-primary" disabled aria-busy="true">
      <span class="ios-spinner" aria-hidden="true"></span>Applying to 40 pages…
    </button>
    <p class="ios-footnote">Keep the app open.</p>
  </div>`);
