import '../styles-editorial.css';

const screen = (inner) => `<div class="screen">${inner}</div>`;

export default { title: 'Editorial/Buttons' };

export const Primary = {
  render: () => screen(`<button type="button" class="btn btn-primary btn-block">Make PDF</button>`),
};

export const Secondary = {
  render: () => screen(`<button type="button" class="btn btn-secondary btn-block">Change pages</button>`),
};

export const Destructive = {
  render: () => screen(`
    <button type="button" class="btn btn-secondary btn-block"
      style="color: var(--color-accent-700); border-color: var(--color-accent-700)">
      Delete the 12 photos (78 MB)
    </button>
    <p class="text-muted" style="font-size:13px;margin-top:var(--space-2)">
      The PDF stays. Deleted photos cannot be brought back.
    </p>`),
};

export const Disabled = {
  render: () => screen(
    `<button type="button" class="btn btn-primary btn-block" disabled>Photograph at least one page</button>`),
};

export const Shutter = {
  render: () => screen(`<div style="display:flex;justify-content:center;padding:var(--space-4) 0">
      <button type="button" class="shutter" aria-label="Photograph page 7"></button>
    </div>`),
};
