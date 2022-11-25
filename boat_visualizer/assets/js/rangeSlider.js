import noUiSlider from 'nouislider';
import 'nouislider/dist/nouislider.css';

export function rangeSlider(hook) {
  let divElement = hook.el;
  const { max } = divElement.dataset;

  noUiSlider.create(divElement, {
    start: [0, parseFloat(max)],
    connect: true,
    range: {
      'min': 0,
      'max': parseFloat(max)
    }
  });
}
