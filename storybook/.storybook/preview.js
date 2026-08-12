const iphone = {
  name: 'iPhone (390x844)',
  type: 'mobile',
  styles: { width: '390px', height: '844px' },
};

/** @type {import('@storybook/html-vite').Preview} */
export default {
  parameters: {
    viewport: { options: { iphone } },
    layout: 'centered',
  },
  initialGlobals: {
    viewport: { value: 'iphone', isRotated: false },
  },
};
