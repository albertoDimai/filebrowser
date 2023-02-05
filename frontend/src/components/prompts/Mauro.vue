<template>
    <div class="card floating">
      <div class="card-title">
        <h2>{{ $t("prompts.mauro") }}</h2>
      </div>
  
      <div class="card-content">
        You are going to execute pdflatex on the file, ok ?
<!--        <file-list @update:selected="(val) => (dest = val)"></file-list>-->
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
          @click="mauro"
          :aria-label="$t('buttons.mauro')"
          :title="$t('buttons.mauro')"
        >
          {{ $t("buttons.mauro") }}
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
    name: "mauro",
    // components: { FileList },
    data: function () {
      return {
        current: window.location.pathname,
        dest: null,
      };
    },
    computed: mapState(["req", "selected"]),
    methods: {
      mauro: async function (event) {
        event.preventDefault();
        let items = [];
  
        for (let item of this.selected) {
          items.push({
            from: this.req.items[item].url
          });
        }
  
        let action = async () => {
          buttons.loading("mauro");
  
          await api
            .mauro(items)
            .then(() => {
              buttons.success("mauro");
              this.$router.push({ path: "#" + Math.random() });

            })
            .catch((e) => {
              buttons.done("mauro");
              this.$showError(e);
            });
        };
        action();
      },
    },
  };
  </script>