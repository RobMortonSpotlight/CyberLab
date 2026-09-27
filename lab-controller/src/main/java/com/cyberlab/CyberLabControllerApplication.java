package com.cyberlab;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.context.annotation.ComponentScan;

@SpringBootApplication
@EnableScheduling
@ComponentScan(basePackages = "com.cyberlab")
public class CyberLabControllerApplication {

    public static void main(String[] args) {
        SpringApplication.run(CyberLabControllerApplication.class, args);
    }
}
