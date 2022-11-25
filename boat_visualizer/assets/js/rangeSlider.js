import noUiSlider from 'nouislider';
import 'nouislider/dist/nouislider.css';

export function rangeSlider(hook) {
  var range = document.getElementById(hook.el.id);

  noUiSlider.create(range, {
    start: [0, 80],
    connect: true,
    range: {
      'min': 0,
      'max': 100
    }
  });
}
