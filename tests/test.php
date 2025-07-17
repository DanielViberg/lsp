<?php

class Test{
	private string $name;
  private int $age;

	public function __construct(string $name, int $age){
		$this->name = $name;
		$this->age = $age;
	}

	public function getName(): string {
		return $this->name;
	}

	public function setAge(int $age): void {
		$this->age = $age;
	}
}
