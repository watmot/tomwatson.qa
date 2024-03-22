import { View as ScreenPreloader } from './ScreenPreloader.view';

describe('<ScreenPreloader />', () => {
  it('should display the preloader without any progress on the bar', () => {
    cy.mount(<ScreenPreloader progress={0} />);
    cy.findByTestId('preloader').should('be.visible');
    cy.findByTestId('preloader_fill').should('not.be.visible');
  });

  it('should no longer display when progress is 100', { defaultCommandTimeout: 6000 }, () => {
    cy.mount(<ScreenPreloader progress={100} />);
    cy.findByTestId('preloader').should('not.be.visible');
  });
});
