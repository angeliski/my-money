# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "chartkick", to: "chartkick.js"
pin "Chart.bundle", to: "Chart.bundle.js"
pin "preline", to: "https://cdn.jsdelivr.net/npm/preline@3.2.3/dist/preline.min.js"


pin "alpinejs", to: "https://ga.jspm.io/npm:alpinejs@3.15.0/dist/module.esm.js"
pin "alpine-turbo-drive-adapter", to: "https://ga.jspm.io/npm:alpine-turbo-drive-adapter@2.2.0/dist/alpine-turbo-drive-adapter.esm.js"
