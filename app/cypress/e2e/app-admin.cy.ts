import { UAParser } from 'ua-parser-js';
import { onlyOn } from '@cypress/skip-test';

describe('AppAdmin', () => {
  const routes = ['/'];
  const env = Cypress.env('NEXT_PUBLIC_BUILD_ENVIRONMENT');

  for (const route of routes) {
    beforeEach(() => {
      cy.visit(route);
    });

    onlyOn(env === 'production', () => {
      it('should not be present on the DOM', () => {
        cy.findByTestId('app-admin').should('not.exist');
      });
    });

    onlyOn(env !== 'production', () => {
      describe(route, () => {
        it('should render', () => {
          cy.findByTestId('app-admin').should('exist').and('be.visible');
        });

        describe('Basic', () => {
          it('should display the build environment', () => {
            const expected = Cypress.env('NEXT_PUBLIC_BUILD_ENVIRONMENT');

            cy.findByRole('listitem', { name: /basic-info-env/i })
              .should('contain.text', expected)
              .and('be.visible');
          });

          it('should display the build version', () => {
            const expected = Cypress.env('NEXT_PUBLIC_BUILD_VERSION');

            cy.findByRole('listitem', { name: /basic-info-version/i })
              .should('contain.text', expected)
              .and('be.visible');
          });
        });

        describe('Expanded', () => {
          beforeEach(() => {
            cy.findByRole('button', { name: /expand/i }).click();
          });

          describe('Device info', () => {
            const userAgent = navigator.userAgent;
            const parser = new UAParser(userAgent);
            const results = parser.getResult();

            it('should display the device type', () => {
              cy.findByRole('listitem', { name: /device-info-device/i })
                .should('contain.text', 'desktop')
                .and('be.visible');
            });

            it('should display the viewport resolution', () => {
              let width = Cypress.config('viewportWidth');
              let height = Cypress.config('viewportHeight');

              cy.findByRole('listitem', { name: /device-info-resolution/i })
                .should('contain.text', `${width} x ${height}`)
                .and('be.visible');

              width = Math.floor(width * 1.5);
              height = Math.floor(height * 1.5);

              cy.viewport(width, height);
              cy.findByRole('listitem', { name: /device-info-resolution/i })
                .should('contain.text', `${width} x ${height}`)
                .and('be.visible');
            });

            it('should display the os name and version', () => {
              const { name, version } = results.os;

              cy.findByRole('listitem', { name: /device-info-os/i })
                .should('contain.text', `${name} ${version}`)
                .and('be.visible');
            });

            it('should display the browser name and version', () => {
              const { name, version } = results.browser;

              cy.findByRole('listitem', { name: /device-info-browser/i })
                .should('contain.text', `${name} ${version}`)
                .and('be.visible');
            });
          });

          describe('Build info', () => {
            it('should display the build environment', () => {
              const expected = Cypress.env('NEXT_PUBLIC_BUILD_ENVIRONMENT');

              cy.findByRole('listitem', { name: /build-info-env/i })
                .should('contain.text', expected)
                .and('be.visible');
            });

            it('should display the build version', () => {
              const expected = Cypress.env('NEXT_PUBLIC_BUILD_VERSION');

              cy.findByRole('listitem', { name: /build-info-version/i })
                .should('contain.text', expected)
                .and('be.visible');
            });

            it('should display the commit id', () => {
              const expected = Cypress.env('NEXT_PUBLIC_COMMIT_ID');

              cy.findByRole('listitem', { name: /build-info-commit/i })
                .should('contain.text', expected)
                .and('be.visible');
            });

            it('should display the datetime of the deployment', () => {
              const expected = Cypress.env('NEXT_PUBLIC_BUILD_DATETIME');
              cy.findByRole('listitem', { name: /build-info-datetime/i })
                .should('contain.text', expected)
                .and('be.visible');
            });
          });
        });
      });
    });
  }
});
