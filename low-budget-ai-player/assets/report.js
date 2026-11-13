(function () {
  'use strict';

  if (window.mermaid) {
    window.mermaid.initialize({
      startOnLoad: true,
      theme: 'neutral',
      securityLevel: 'loose',
      flowchart: {
        htmlLabels: true,
        curve: 'basis'
      }
    });
  }

  var printButton = document.getElementById('print-button');
  if (printButton) {
    printButton.addEventListener('click', function () {
      window.print();
    });
  }
})();
