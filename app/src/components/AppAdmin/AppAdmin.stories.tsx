import type { Meta, StoryObj } from '@storybook/react';

import View from './AppAdmin.view';

const meta: Meta<typeof View> = {
  component: View
};

export default meta;

type Story = StoryObj<typeof View>;

export const Default: Story = {
  args: {
    isDev: true,
    build: { env: 'local', version: '167', commit: '1234adb', datetime: '01/04/1992 05:00:00' },
    device: {
      device: 'desktop',
      resolution: '1920 x 1080',
      os: 'macos 15.5.7',
      browser: 'chrome 122.0.0.0'
    }
  }
};
