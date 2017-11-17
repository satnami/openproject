//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

jQuery(function($) {
  let $filterForm = $('form.project-filters').first();
  let $button = $('#projects-filter-toggle-button');
  let operatorsWithoutValues = ['*', '!*'];
  let operatorsWithVaues = ['*', '!*'];
  let selectFilterTypes = ['list', 'list_all', 'list_optional'];

  function toggleProjectFilterForm() {
    if($button.hasClass('-active')) {
      $button.removeClass('-active');
      $filterForm.removeClass('-expanded');
    } else {
      $button.addClass('-active');
      $filterForm.addClass('-expanded');
    }
  }

  function sendForm() {
    $('#ajax-indicator').show();
    let $advancedFilters = $(".advanced-filters--filter:not(.hidden)", $filterForm);
    let filters = [];
    $advancedFilters.each(function(_i, filter){
      let $filter = $(filter);
      let filterName = $filter.attr('filter-name');
      let filterType = $filter.attr('filter-type');
      let operator = $('select[name="operator"]', $filter).val();

      let filterParam = {};

      if (operatorsWithoutValues.includes(operator)) {
        // operator does not expect a value
        filterParam[filterName] = {
          'operator': operator,
          'values': []
        }
        filters.push(filterParam);
      } else {
        // Operator expects presence of value(s)
        let $valueBlock = $('.advanced-filters--filter-value', $filter);
        if (selectFilterTypes.includes(filterType)) {
          if ($valueBlock.hasClass('multi-value')) {
            // Expect values to be an Array.
            let values = $('.multi-select select[name="value[]"]', $valueBlock).val();
            if (values.length > 0) {
              filterParam[filterName] = {
                'operator': operator,
                'values': values
              }
              // only add filter if a value is present.
              filters.push(filterParam);
            }
          } else {
            // Expect value to be a single value.
            let value = $('.single-select select[name="value"]', $valueBlock).val();
            if (value.length > 0) {
              filterParam[filterName] = {
                'operator': operator,
                'values': [value]
              }
              // only add filter if a value is present.
              filters.push(filterParam);
            }
          }
        } else {
          // not a select box
          let value = $('input[name="value"]', $valueBlock).val();
          if (value.length > 0) {
            filterParam[filterName] = {
              'operator': operator,
              'values': [value]
            }
            // only add filter if a value is present.
            filters.push(filterParam);
          }
        }
      }
    })
    let query = '?filters=' + encodeURIComponent(JSON.stringify(filters));
    window.location = window.location.pathname + query;
    return false;
  }

  function toggleMultiselect(){
    let $self = $(this);
    let $valueSelector = $self.parents('.advanced-filters--filter-value');

    let $singleSelect = $('.single-select select', $valueSelector);
    let $multiSelect  = $('.multi-select select', $valueSelector);

    if ($valueSelector.hasClass('multi-value')) {
      let values = $singleSelect.val();
      let value = null;
      if (values && values.length > 1) {
        value = values[0];
      } else {
        value = values;
      }
      $singleSelect.val(value);
    } else {
      let value = $multiSelect.val();
      $singleSelect.val(value);
    }

    $valueSelector.toggleClass('multi-value');
    return false;
  }

  function addFilter(e) {
    e.preventDefault();
    $('[filter-name="' + $(this).val() + '"]').removeClass('hidden');
    $('#add_filter_select option:selected', $filterForm).remove();
    return false;
  }

  function removeFilter(e) {
    $(this).parents('.advanced-filters--filter').addClass('hidden');
  }

  function setValueVisibility() {
    $selectedOperator = $(this).val();
    $filter = $(this).parents('.advanced-filters--filter')
    $filterValue = $('.advanced-filters--filter-value', $filter);
    if (['*', '!*'].includes($selectedOperator)) {
      $filterValue.addClass('hidden');
    } else {
      $filterValue.removeClass('hidden');
    }


  }

  // Register event listeners
  $('.advanced-filters--filter-value span.multi-select-toggle').click(toggleMultiselect);
  $button.click(toggleProjectFilterForm);
  $filterForm.submit(sendForm);
  $('select[name="operator"]', $filterForm).on('change', setValueVisibility)
  $('#add_filter_select', $filterForm).on('change', addFilter);
  $('.filter_rem', $filterForm).on('click', removeFilter);
});
