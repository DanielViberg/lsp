<script setup>
import Test2 from './Test2.vue'

const thisIsAVariable = defineProps()

</script>
<style>
.test {
	display: grid;
}
</style>

<template>
	<div :class="thisIsAVariable">
		<div :class="thisIsAVariable"></div>
	</div>
	<Test2>
	</Test2>
</template>
