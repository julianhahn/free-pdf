import '../styles-editorial.css';

const chevron = `<svg class="scan-row-chevron" width="18" height="18" viewBox="0 0 24 24" fill="none"
  stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"
  aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg>`;

const row = (date, subtitle) => `
  <button type="button" class="scan-row" aria-label="${date}. ${subtitle}">
    <span class="scan-row-text">
      <span class="scan-row-title">${date}</span>
      <span class="scan-row-sub">${subtitle}</span>
    </span>
    ${chevron}
  </button>`;

const screen = (inner) => `<div class="screen"><ul style="list-style:none;margin:0;padding:0">
  <li>${inner}</li></ul></div>`;

export default {
  title: 'Editorial/Scan row',
  render: ({ date, subtitle }) => screen(row(date, subtitle)),
  args: { date: '11 Aug 2026, 20:14' },
};

export const NoPagesYet = { args: { date: '09 Aug 2026, 18:02', subtitle: 'No pages yet' } };
export const Shooting = { args: { subtitle: '8 pages — keep shooting' } };
export const ShootingOnePage = { args: { subtitle: '1 page — keep shooting' } };
export const Scanning = { args: { date: '11 Aug 2026, 09:32', subtitle: '12 of 40 pages scanned' } };
export const ReadyToCheck = { args: { subtitle: '40 pages — ready to check' } };
export const PdfReady = { args: { subtitle: '40 pages — PDF ready' } };
export const PdfReadyPhotosDeleted = { args: { subtitle: '40 pages — PDF ready, photos deleted' } };

export const SwipeToDelete = {
  render: () => screen(`<div class="swipe">
      <button type="button" class="swipe-action">Delete</button>
      ${row('11 Aug 2026, 20:14', '40 pages — PDF ready')}
    </div>`),
};
