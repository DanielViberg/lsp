<script setup>
const thisIsAVariable = defineProps()
const thisI2Variable = defineSlots()

</script>
<style>
.test {
	display: grid;
	align-self: center;
	display: grid;
}
</style>

<template>
	<div :class="thisIsAVariable"
	     :style="thisI2Variable"></div>
</template>
