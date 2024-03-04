describe('Navigation', () => {
  it('should navigate to the homepage', () => {
    cy.visit('/');

    cy.findByRole('heading', { name: /tomwatson.qa website/i }).should('be.visible');
  });
});
