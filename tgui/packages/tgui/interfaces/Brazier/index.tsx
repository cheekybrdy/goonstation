/**
 * @file
 * @copyright 2024
 * @author DisturbHerb (https://github.com/cheekybrdy)
 * @license MIT
 */

import {
  Button,
  Collapsible,
  Dimmer,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../../backend';
import { Window } from '../../layouts';
import { capitalize } from '../common/stringUtils';
import { Phonebook, PhoneData } from './type';

const PantheonColors = [
  { pantheon: 'divine', color: 'light-grey' },
  { pantheon: 'scorched', color: 'red' },
  { pantheon: 'drowned', color: 'navy' },
  { pantheon: 'nature', color: 'green' },
  { pantheon: 'light', color: 'yellow' },
  { pantheon: 'outlander', color: 'teal' },
  { pantheon: '???', color: 'violet' },
];

const categorySort = (a, b) => a.category.localeCompare(b.category);
const idSort = (a, b) => a.id.localeCompare(b.id);

export const Brazier = () => {
  const { data } = useBackend<PhoneData>();
  const { dialing, inCall, lastCalled, name } = data;
  const pantheon = data.pantheon.sort(categorySort) || [];

  return (
    <Window title={name} width={250} height={350}>
      <Window.Content>
        {(!pantheon_selected) && (
          <Dimmer>
            <h1>Select A Pantheon.</h1>
          </Dimmer>
        )}
        <Stack vertical fill>
          <Stack.Item grow={1}>
            <Section title="Pantheons" fill scrollable>
              {pantheon.map((category) => (
                <AddressGroup key={category.category} phonebook={category} />
              ))}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

type AddressGroupProps = {
  phonebook: Phonebook;
};

const AddressGroup = ({ phonebook }: AddressGroupProps) => {
  const { act } = useBackend<PhoneData>();
  const categoryName = capitalize(phonebook.category);
  const phones = phonebook.phones.sort(idSort);

  const getCategoryColor =
    CategoryColors[
      CategoryColors.findIndex(
        ({ pantheon }) => pantheon === phonebook.category,
      )
    ].color;

  return (
    <Collapsible
      title={categoryName}
      color={!!getCategoryColor && getCategoryColor}
    >
      {phones.map((currentPhone) => (
        <Button
          fluid
          key={currentPhone.id}
          onClick={() => act('call', { target: currentPhone.id })}
          textAlign="center"
          className="phone__button"
        >
          {currentPhone.id}
        </Button>
      ))}
    </Collapsible>
  );
};
