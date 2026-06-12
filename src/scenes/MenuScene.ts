import Phaser from 'phaser';
import { Controls, GAME_HEIGHT, GAME_WIDTH, LEVEL_NAME } from '../shared/constants';
import { ControllerInput } from '../input/ControllerInput';

export class MenuScene extends Phaser.Scene {
  private controller?: ControllerInput;

  constructor() {
    super('MenuScene');
  }

  create(): void {
    this.add.rectangle(0, 0, GAME_WIDTH, GAME_HEIGHT, 0x180716).setOrigin(0);
    this.add.rectangle(0, GAME_HEIGHT - 92, GAME_WIDTH, 92, 0x3b1814).setOrigin(0);
    this.add.text(GAME_WIDTH / 2, 94, 'PIZZA FISH TACO', {
      fontFamily: 'monospace',
      fontSize: '48px',
      color: '#ffffff',
      stroke: '#000000',
      strokeThickness: 8,
    }).setOrigin(0.5);
    this.add.text(GAME_WIDTH / 2, 148, 'DEFENDS THE PLANET', {
      fontFamily: 'monospace',
      fontSize: '28px',
      color: '#37e6ff',
      stroke: '#000000',
      strokeThickness: 6,
    }).setOrigin(0.5);
    this.add.image(GAME_WIDTH / 2, 280, 'pizza-fish-taco').setScale(2.4);
    this.add.text(GAME_WIDTH / 2, 410, `${LEVEL_NAME}\nPress ${Controls.start} to start`, {
      fontFamily: 'monospace',
      fontSize: '24px',
      align: 'center',
      color: '#ffe964',
      stroke: '#000000',
      strokeThickness: 5,
    }).setOrigin(0.5);
    this.add.text(GAME_WIDTH / 2, 500, 'Move: A/D or Arrows   Jump: Space   Combo: J   Heavy: K   Sauce Spin: L', {
      fontFamily: 'monospace',
      fontSize: '16px',
      color: '#ffffff',
      stroke: '#000000',
      strokeThickness: 4,
    }).setOrigin(0.5);
    this.add.text(GAME_WIDTH / 2, 522, Controls.controller, {
      fontFamily: 'monospace',
      fontSize: '14px',
      color: '#37e6ff',
      stroke: '#000000',
      strokeThickness: 4,
    }).setOrigin(0.5);

    this.controller = new ControllerInput(this);
    this.input.keyboard?.once('keydown-ENTER', () => this.scene.start('LevelScene'));
  }

  update(): void {
    if (this.controller?.read().startPressed) {
      this.scene.start('LevelScene');
    }
  }
}
