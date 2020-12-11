describe('buckinghamshire cobrand', function() {

  beforeEach(function() {
    cy.server();
    cy.route('**mapserver/bucks*Whole_Street*', 'fixture:roads.xml').as('roads-layer');
    cy.route('**mapserver/bucks*WinterRoutes*', 'fixture:roads.xml').as('winter-routes');
    cy.route('/report/new/ajax*').as('report-ajax');
    cy.route('/around/nearby*').as('around-ajax');
    cy.visit('http://buckinghamshire.localhost:3001/');
    cy.contains('Buckinghamshire');
    cy.get('[name=pc]').type('SL9 0NX');
    cy.get('[name=pc]').parents('form').submit();
  });

  it('sets the site_code correctly', function() {
    cy.get('.olMapViewport #fms_pan_zoom_zoomin').click();
    cy.wait('@roads-layer');
    cy.get('#map_box').click(290, 307);
    cy.wait('@report-ajax');
    cy.get('select:eq(4)').select('Parks');
    cy.get('[name=site_code]').should('have.value', '7300268');
  });

  it('uses the label "Full name" for the name field', function() {
    cy.get('#map_box').click(290, 307);
    cy.wait('@report-ajax');
    cy.get('select:eq(4)').select('Flytipping');
    cy.wait('@around-ajax');

    cy.get('.js-reporting-page--next:visible').click();
    cy.get('.js-reporting-page--next:visible').click(); // No photo
    cy.get('[name=title]').type('Title');
    cy.get('[name=detail]').type('Detail');
    cy.get('.js-reporting-page--next:visible').click();
    cy.get('label[for=form_name]').should('contain', 'Full name');
  });

  it('shows gritting message', function() {
    cy.get('.olMapViewport #fms_pan_zoom_zoomin').click();
    cy.wait('@roads-layer');
    cy.get('#map_box').click(290, 307);
    cy.wait('@report-ajax');
    cy.get('select').eq(4).select('Snow and ice problem/winter salting');
    cy.wait('@winter-routes');
    cy.get('.js-reporting-page--next:visible').click();
    cy.contains('The road you have selected is on a regular gritting route').should('be.visible');
  });

});

describe('buckinghamshire roads handling', function() {
  it('makes you move the pin if not on a road', function() {
    cy.server();
    cy.route('**mapserver/bucks*Whole_Street*', 'fixture:roads.xml').as('roads-layer');
    cy.route('/report/new/ajax*').as('report-ajax');
    cy.viewport(480, 800);
    cy.visit('http://buckinghamshire.localhost:3001/');
    cy.get('[name=pc]').type('SL9 0NX');
    cy.get('[name=pc]').parents('form').submit();

    cy.get('.olMapViewport #fms_pan_zoom_zoomin').click({ force: true }); // Sometimes zoom appearing too high under, but not if I try manually
    cy.wait('@roads-layer');
    cy.get('#map_box').click(290, 307);
    cy.wait('@report-ajax');
    cy.get('#mob_ok').click();
    cy.get('select:eq(4)').select('Parks');
    cy.get('.js-reporting-page--next:visible').click();
    cy.contains('Please select a road on which to make a report.').should('be.visible');
  });
});
