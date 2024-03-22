describe('Preload', () => {
  it('should preload all binaries hide the preloader once complete', () => {
    cy.intercept('GET', '/_next/static/media/*').as('assetBinaries');
    cy.intercept({ hostname: 's3.amazonaws.com' }).as('storyblokBinaries');

    cy.visit('/');
    cy.findAllByTestId('preloader').should('be.visible');
    cy.wait(['@assetBinaries', '@storyblokBinaries']).then(() => {
      cy.findAllByTestId('preloader', { timeout: 10000 }).should('not.be.visible');
    });
  });
});
