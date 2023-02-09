<template>
    <div class="card floating">
      <div class="card-title">
        <h2>{{ $t("prompts.mauro_pdflatex") }}</h2>
      </div>
  
      <div class="card-content">
        Execute pdflatex on the file ?
        <div style="padding-top: 15px;">
          <input style="margin: 5px;" type="checkbox" id="checkbox" ref="theCheckbox" checked="true">
          <label for="checkbox">load result</label>
        </div>
      </div>
  
      <div class="card-action">
        <button
          class="button button--flat button--grey"
          @click="$store.commit('closeHovers')"
          :aria-label="$t('buttons.cancel')"
          :title="$t('buttons.cancel')"
        >
          {{ $t("buttons.cancel") }}
        </button>
        <button
          class="button button--flat"
          @click="mauro_pdflatex"
          :aria-label="$t('buttons.mauro_pdflatex')"
          :title="$t('buttons.mauro_pdflatex')"
        >
          {{ $t("buttons.mauro_pdflatex") }}
        </button>
      </div>
    </div>
  </template>
  
  <script>
  import { mapState } from "vuex";
  // import FileList from "./FileList";
  import { files as api } from "@/api";
  import buttons from "@/utils/buttons";
  
  export default {
    name: "mauro_pdflatex",
    // components: { FileList },
    data: function () {
      return {
        current: window.location.pathname,
        dest: null,
      };
    },
    computed: mapState(["req", "selected"]),
    methods: {
      mauro_pdflatex: async function (event) {
        event.preventDefault();
        let items = [];
  
        for (let item of this.selected) {
          items.push({
            from: this.req.items[item].url
          });
        }
        let action = async () => {
          const load_result = this.$refs.theCheckbox.checked;
          buttons.loading("mauro_pdflatex");

          await api
            .mauro("pdflatex",items)
            .then(() => {
              buttons.success("mauro_pdflatex");

              if(load_result)
                this.$router.push({ path: items[0].from + ".pdflatex.OUT.log" }); //convenzione
              else
                this.$router.push({ path: "#" + Math.random() });
            })
            .catch((e) => {
              buttons.done("mauro_pdflatex");
              this.$showError(e);
            });
        };
        action();
      },
    },
  };
  </script>