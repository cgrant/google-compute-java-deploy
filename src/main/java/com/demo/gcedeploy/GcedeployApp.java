package com.demo.gcedeploy;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;


import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;


@SpringBootApplication
@RestController
public class GcedeployApp {

	public static void main(String[] args) {
		SpringApplication.run(GcedeployApp.class, args);
	}

	@RequestMapping("/")
  public String hello(){
  	return "hello";
  }
}
