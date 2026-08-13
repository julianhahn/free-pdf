// The one file the design system says a consumer links. Without it every story
// renders as unstyled HTML, which is exactly what happened.
import "@ds/styles.css";

const iphone = {
  name: 'iPhone (390x844)',
  type: 'mobile',
  styles: { width: '390px', height: '844px' },
};

/** @type {import('@storybook/react-vite').Preview} */
export default {
  parameters: {
    viewport: { options: { iphone } },
    layout: 'centered',
  },
  initialGlobals: {
    viewport: { value: 'iphone', isRotated: false },
  },
};
