import { View as PageHome } from './PageHome.view';

describe('PageHome', () => {
  it('should display a header', () => {
    cy.mount(<PageHome title="tomwatson.qa website" />);

    cy.findByRole('heading', { name: /tomwatson.qa website/i }).should('be.visible');
  });
});
