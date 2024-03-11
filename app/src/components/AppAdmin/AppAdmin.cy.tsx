import { View as AppAdmin, ViewProps } from './AppAdmin.view';

const props: ViewProps = {
  isDev: true,
  build: { env: 'local', version: '167', commit: '1234abc', datetime: '01/04/1992 05:00:00' },
  device: {
    device: 'desktop',
    resolution: '1920 x 1080',
    os: 'macos 10.15.7',
    browser: 'chrome 122.0.0.0'
  }
};

describe('AppAdmin', () => {
  it('should intially render in the collapsed state', () => {
    cy.mount(<AppAdmin {...props} />);

    // Basic info should exist
    cy.findByTestId('basic').within(() => {
      cy.findByRole('listitem', { name: /basic-info-env/i })
        .should('contain.text', props.build.env)
        .and('be.visible');
      cy.findByRole('listitem', { name: /basic-info-version/i })
        .should('contain.text', props.build.version)
        .and('be.visible');
    });

    cy.findByRole('button', { name: /hide admin/i }).should('be.visible');
    cy.findByRole('button', { name: /expand admin/i }).should('be.visible');

    // Expanded info should not exist
    cy.findByTestId('expanded').should('not.exist');
  });

  it('should expand and collapse when clicked', () => {
    cy.mount(<AppAdmin {...props} />);

    // Click to expand the admin panel
    cy.findByRole('button', { name: /expand admin/i }).click();
    cy.findByTestId('expanded').within(() => {
      // Device info should exist
      cy.findByTestId('device').within(() => {
        cy.findByRole('heading', { name: /device info/i }).should('be.visible');

        for (const entry of Object.entries(props.device)) {
          cy.findByRole('listitem', { name: new RegExp(`device-info-${entry[0]}`, 'i') })
            .should('be.visible')
            .should('contain.text', entry[1]);
        }
      });
      // Build info should exist
      cy.findByTestId('build').within(() => {
        cy.findByRole('heading', { name: /build info/i }).should('be.visible');

        for (let entry of Object.entries(props.build)) {
          cy.findByRole('listitem', { name: new RegExp(`build-info-${entry[0]}`, 'i') })
            .should('be.visible')
            .should('contain.text', entry[1]);
        }
      });
      // Remove from DOM button
      cy.findByRole('button', { name: /remove from dom/i }).should('be.visible');
    });

    // Basic info should still exist
    cy.findByTestId('basic').within(() => {
      cy.findByRole('listitem', { name: /basic-info-env/i })
        .should('contain.text', props.build.env)
        .and('be.visible');
      cy.findByRole('listitem', { name: /basic-info-version/i })
        .should('contain.text', props.build.version)
        .and('be.visible');
    });

    cy.findByRole('button', { name: /hide admin/i }).should('be.visible');

    // Click to collapse the admin panel
    cy.findByRole('button', { name: /collapse admin/i })
      .should('be.visible')
      .click();

    // Expanded info should no longer exist on the DOM
    cy.findByTestId('expanded').should('not.exist');

    // Basic info should still exist
    cy.findByTestId('basic').within(() => {
      cy.findByRole('listitem', { name: /basic-info-env/i })
        .should('contain.text', props.build.env)
        .and('be.visible');
      cy.findByRole('listitem', { name: /basic-info-version/i })
        .should('contain.text', props.build.version)
        .and('be.visible');
    });
  });

  it('should be hidden and shown if clicked when collapsed', () => {
    cy.mount(<AppAdmin {...props} />);

    // Click to hide the admin panel
    cy.findByRole('button', { name: /hide admin/i }).click();
    cy.findByTestId('basic').within(() => {
      cy.findByTestId('info').should('not.exist');
    });

    cy.findByTestId('expanded').should('not.exist');
    cy.findByRole('button', { name: /(expand|collapse) admin/i }).should('not.exist');

    // Click to show the admin panel
    cy.findByRole('button', { name: /show admin/i }).click();
    cy.findByRole('button', { name: /hide admin/i }).should('be.visible');
    cy.findByTestId('basic').within(() => {
      cy.findByRole('listitem', { name: /basic-info-env/i })
        .should('contain.text', props.build.env)
        .and('be.visible');
      cy.findByRole('listitem', { name: /basic-info-version/i })
        .should('contain.text', props.build.version)
        .and('be.visible');
    });
    cy.findByTestId('expanded').should('not.exist');
  });

  it('should be hidden and shown if clicked when expanded', () => {
    cy.mount(<AppAdmin {...props} />);

    // Click to expand, and then hide, the admin panel
    cy.findByRole('button', { name: /expand admin/i }).click();
    cy.findByRole('button', { name: /hide admin/i }).click();

    // The basic or expanded info should not exist
    cy.findByTestId('basic').within(() => {
      cy.findByTestId('info').should('not.exist');
    });
    cy.findByTestId('expanded').should('not.exist');
    cy.findByRole('button', { name: /(expand|collapse) admin/i }).should('not.exist');

    // Click to show the admin panel
    cy.findByRole('button', { name: /show admin/i }).click();

    cy.findByRole('button', { name: /hide admin/i }).should('be.visible');

    // The basic info should exist
    cy.findByTestId('basic').within(() => {
      cy.findByRole('listitem', { name: /basic-info-env/i })
        .should('contain.text', props.build.env)
        .and('be.visible');
      cy.findByRole('listitem', { name: /basic-info-version/i })
        .should('contain.text', props.build.version)
        .and('be.visible');
    });

    // The expanded info should not exist
    cy.findByTestId('expanded').should('not.exist');
  });

  it('should be removed from the DOM when clicked', () => {
    cy.mount(<AppAdmin {...props} />);

    cy.findByRole('button', { name: /expand admin/i }).click();
    cy.findByRole('button', { name: /remove from dom/i }).click();
    cy.findByTestId('app-admin').should('not.exist');
  });

  it('should not display in the DOM when isDev === false', () => {
    cy.mount(<AppAdmin {...props} isDev={false} />);

    cy.findByTestId('app-admin').should('not.exist');
  });
});
