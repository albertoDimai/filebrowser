<template>
  <div id="login" :class="{ recaptcha: recaptcha }">

    <div style="max-width: 70em; margin:auto; font-size: 120%;">
      <h1 style="text-align: center;"><i>Mauro</i>-<tt>T<sub>E</sub>X</tt></h1>
      <h3 style="text-align: center;">
        Piattaforma online per l'allestimento e la gestione <br/>
        di un'edizione critica
      </h3>
      <div>
        Sviluppato nell'ambito dell'Edizione Nazionale dell'Opera matematica di Francesco Maurolico
        (<a href="http://www.maurolico.it" target="__BLANK">www.maurolico.it</a>), il
        <i>Mauro</i>-<tt>T<sub>E</sub>X</tt>
        è un linguaggio e un insieme di applicazioni che permettono di
        <ul>
          <li>
            fornire il testo critico di un'opera che tenga conto di tutta la tradizione manoscritta ed a stampa e
            che rispetti determinati standard di qualità e di eleganza filologica; </li>
          <li>
            registrare, attraverso l'utilizzo di un opportuno sistema di descrizione, un elevato numero di informazioni
            filologiche relative al testo, in modo da permettere, in particolare, il recupero integrale dei diversi
            testimoni sui quali è stato costruito il testo critico; </li>
          <li>
            uniformare, nell'ambito di un gruppo di collaboratori numeroso, la presentazione ed i criteri editoriali.
          </li>
        </ul>
      </div>
         <div style="text-align: center; position: absolute; bottom: 15px; left: 0; right: 0; font-size: 12px;">
      	      per richiedere un account per l'accesso scrivere a
               <a target="__BLANK" href="mailto:alberto.mancini@unifi.it">alberto.mancini@unifi.it</a>
         </div>
         <div	style="font-size: 8px; text-align: right; position: absolute; bottom: 1px; left: 0; right: 10px; color: blue;">version 4.0410</div>
    </div>
    
    <form @submit="submit">
      <!-- <img :src="logoURL" alt="File Browser" /> -->
      <!-- <h1>{{ name }}</h1> -->
      <div v-if="error !== ''" class="wrong">{{ error }}</div>

      <input
        autofocus
        class="input input--block"
        type="text"
        autocapitalize="off"
        v-model="username"
        :placeholder="t('login.username')"
      />
      <input
        class="input input--block"
        type="password"
        v-model="password"
        :placeholder="t('login.password')"
      />
      <input
        class="input input--block"
        v-if="createMode"
        type="password"
        v-model="passwordConfirm"
        :placeholder="t('login.passwordConfirm')"
      />

      <div v-if="recaptcha" id="recaptcha"></div>
      <input
        class="button button--block"
        type="submit"
        :value="createMode ? t('login.signup') : t('login.submit')"
      />

      <p @click="toggleMode" v-if="signup">
        {{ createMode ? t("login.loginInstead") : t("login.createAnAccount") }}
      </p>
    </form>
  </div>
</template>

<script setup lang="ts">
import { StatusError } from "@/api/utils";
import * as auth from "@/utils/auth";
import {
  name,
  logoURL,
  recaptcha,
  recaptchaKey,
  signup,
} from "@/utils/constants";
import { inject, onMounted, ref } from "vue";
import { useI18n } from "vue-i18n";
import { useRoute, useRouter } from "vue-router";

// Define refs
const createMode = ref<boolean>(false);
const error = ref<string>("");
const username = ref<string>("");
const password = ref<string>("");
const passwordConfirm = ref<string>("");

const route = useRoute();
const router = useRouter();
const { t } = useI18n({});
// Define functions
const toggleMode = () => (createMode.value = !createMode.value);

const $showError = inject<IToastError>("$showError")!;

const submit = async (event: Event) => {
  event.preventDefault();
  event.stopPropagation();

  const redirect = (route.query.redirect || "/files/") as string;

  let captcha = "";
  if (recaptcha) {
    captcha = window.grecaptcha.getResponse();

    if (captcha === "") {
      error.value = t("login.wrongCredentials");
      return;
    }
  }

  if (createMode.value) {
    if (password.value !== passwordConfirm.value) {
      error.value = t("login.passwordsDontMatch");
      return;
    }
  }

  try {
    if (createMode.value) {
      await auth.signup(username.value, password.value);
    }

    await auth.login(username.value, password.value, captcha);
    router.push({ path: redirect });
  } catch (e: any) {
    // console.error(e);
    if (e instanceof StatusError) {
      if (e.status === 409) {
        error.value = t("login.usernameTaken");
      } else if (e.status === 403) {
        error.value = t("login.wrongCredentials");
      } else {
        $showError(e);
      }
    }
  }
};

// Run hooks
onMounted(() => {
  if (!recaptcha) return;

  window.grecaptcha.ready(function () {
    window.grecaptcha.render("recaptcha", {
      sitekey: recaptchaKey,
    });
  });
});
</script>
