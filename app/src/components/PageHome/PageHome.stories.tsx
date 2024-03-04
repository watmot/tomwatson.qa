import type { Meta, StoryObj } from '@storybook/react';

import View from './PageHome.view';

const meta: Meta<typeof View> = {
  component: View
};

export default meta;

type Story = StoryObj<typeof View>;

export const Main: Story = {
  args: {
    title: 'tomwatson.qa website'
  }
};
