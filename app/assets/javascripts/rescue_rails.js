window.RescueRails = {
  saveParentForm: function() {
    var $form = $(this).parent('form');
    var serialized_form = $form.serialize();
    var $status = $form.find('#status-icon');
    $status.removeClass('fa-check fa-times');

    $.ajax({
      url: $form.attr('action'),
      type: 'POST',
      data: serialized_form
    })
    .done( function(data) {
      $status.addClass('fa fa-check');
      $status.show();
      $status.fadeOut(3000);
    })
    .fail( function(data) {
      $status.addClass('fa fa-times');
      $status.show();
      $status.fadeOut(3000);
    })
  }
};

