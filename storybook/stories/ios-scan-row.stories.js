import '../styles-ios.css';

export default { title: 'Variant A — iOS/Scan row' };

const row = (title, subtitle) => `
  <ul class="ios ios-list">
    <li>
      <button type="button" class="ios-row" aria-label="${title}, ${subtitle}">
        <span class="ios-row-text">
          <span class="ios-row-title">${title}</span>
          <span class="ios-row-subtitle">${subtitle}</span>
        </span>
        <span class="ios-chevron" aria-hidden="true">›</span>
      </button>
    </li>
  </ul>`;

const DATE = '11 Aug 2026, 20:14';

export const NoPagesYet = () => row('09 Aug 2026, 18:02', 'No pages yet');
export const ShootingOnePage = () => row(DATE, '1 page — keep shooting');
export const Shooting = () => row(DATE, '8 pages — keep shooting');
export const Scanning = () => row('11 Aug 2026, 09:32', '12 of 40 pages scanned');
export const ReadyToCheck = () => row(DATE, '40 pages — ready to check');
export const PdfReady = () => row(DATE, '40 pages — PDF ready');
export const PdfReadyPhotosDeleted = () =>
  row(DATE, '40 pages — PDF ready, photos deleted');

export const SwipeToDelete = () => `
  <ul class="ios ios-list">
    <li class="ios-swipe">
      <button type="button" class="ios-row" aria-label="${DATE}, 40 pages — PDF ready">
        <span class="ios-row-text">
          <span class="ios-row-title">${DATE}</span>
          <span class="ios-row-subtitle">40 pages — PDF ready</span>
        </span>
        <span class="ios-chevron" aria-hidden="true">›</span>
      </button>
      <button type="button" class="ios-swipe-action">Delete</button>
    </li>
  </ul>`;
