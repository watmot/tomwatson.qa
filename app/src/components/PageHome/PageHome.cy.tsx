import { PageHome } from '.';

describe('PageHome', () => {
  it('should display a header', () => {
    cy.mount(<PageHome />);

    cy.findByRole('heading', { name: /tomwatson.qa website/i }).should('be.visible');
  });
});
