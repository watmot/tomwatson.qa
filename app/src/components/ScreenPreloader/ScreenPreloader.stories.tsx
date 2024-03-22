import type { Meta, StoryObj } from '@storybook/react';

import View from './ScreenPreloader.view';

const meta: Meta<typeof View> = {
  component: View,
  argTypes: {
    progress: {
      control: {
        type: 'range',
        min: 0,
        max: 100
      }
    }
  }
};

export default meta;

type Story = StoryObj<typeof View>;

export const Default: Story = {
  args: {
    progress: 0
  }
};
