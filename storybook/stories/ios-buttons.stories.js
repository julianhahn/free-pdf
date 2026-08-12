import '../styles-ios.css';

export default { title: 'Variant A — iOS/Buttons' };

const stack = (inner) => `<div class="ios"><div class="ios-stack">${inner}</div></div>`;

export const Primary = () =>
  stack(`<button type="button" class="ios-btn ios-btn-primary">Make PDF</button>`);

export const PrimaryRunning = () =>
  stack(`<button type="button" class="ios-btn ios-btn-primary" aria-busy="true">
    <span class="ios-spinner" aria-hidden="true"></span>Making the PDF…
  </button>`);

export const Secondary = () =>
  stack(`<button type="button" class="ios-btn ios-btn-secondary">Change pages</button>`);

export const Destructive = () =>
  stack(`
    <button type="button" class="ios-btn ios-btn-destructive">Delete the 12 photos (78 MB)</button>
    <p class="ios-footnote">The PDF stays. Deleted photos cannot be brought back.</p>`);

export const Disabled = () =>
  stack(`<button type="button" class="ios-btn" disabled aria-label="Photograph at least one page">
    Photograph at least one page
  </button>`);

export const Shutter = () => `
  <div class="ios">
    <button type="button" class="ios-shutter" aria-label="Photograph page 7">
      <span aria-hidden="true"></span>
    </button>
  </div>`;
